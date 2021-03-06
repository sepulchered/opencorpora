#!/usr/bin/perl

use strict;
use utf8;
use DBI;
use Encode;
use Config::INI::Reader;
use Getopt::constant('FORCE' => 0, 'PLAINTEXT' => 0);

#reading config
my $conf = Config::INI::Reader->read_handle(\*STDIN);
$conf = $conf->{mysql};

#main
my $dbh = DBI->connect('DBI:mysql:'.$conf->{'dbname'}.':'.$conf->{'host'}, $conf->{'user'}, $conf->{'passwd'});
if (!$dbh) {
    die $DBI::errstr;
}
$dbh->do("SET NAMES utf8");
binmode(STDOUT, ':utf8');

my $ts = $dbh->prepare("SELECT MAX(`timestamp`) `timestamp` FROM `rev_sets` WHERE `set_id` IN ((SELECT `set_id` FROM dict_revisions ORDER BY `rev_id` DESC LIMIT 1), (SELECT `set_id` FROM dict_links_revisions ORDER BY `rev_id` DESC LIMIT 1))");
$ts->execute();
my $r = $ts->fetchrow_hashref();
if (time() - $r->{'timestamp'} > 60*60*25 && !FORCE) {
    exit();
}

my $rev = $dbh->prepare("SELECT MAX(rev_id) AS m FROM dict_revisions");
my $read_g = $dbh->prepare("SELECT g1.inner_id AS id, g1.outer_id AS rus_name, g1.gram_descr, g2.inner_id AS pid FROM gram g1 LEFT JOIN gram g2 ON (g1.parent_id=g2.gram_id) ORDER BY g1.`orderby`");
my $read_r = $dbh->prepare("
    SELECT g1.inner_id AS left_gram, g2.inner_id AS right_gram, restr_type, obj_type, auto
    FROM gram_restrictions r
    LEFT JOIN gram g1 ON (r.if_id = g1.gram_id)
    LEFT JOIN gram g2 ON (r.then_id = g2.gram_id)
");
my $read_l = $dbh->prepare("SELECT * FROM (SELECT lemma_id, rev_id, rev_text FROM dict_revisions LEFT JOIN dict_lemmata dl USING (lemma_id) WHERE dl.lemma_text IS NOT NULL AND lemma_id BETWEEN ? AND ? ORDER BY lemma_id, rev_id DESC) T GROUP BY T.lemma_id");
my $read_lt = $dbh->prepare("SELECT * FROM dict_links_types ORDER BY link_id");
my $read_links = $dbh->prepare("SELECT * FROM dict_links ORDER BY link_id LIMIT ?, 10000");
my %restr_types = (
    0 => 'maybe',
    1 => 'obligatory',
    2 => 'forbidden'
);
my %obj_types = (
    0 => ['lemma', 'lemma'],
    1 => ['lemma', 'form'],
    2 => ['form', 'lemma'],
    3 => ['form', 'form']
);

$rev->execute();
$r = $rev->fetchrow_hashref();
my $maxrev = $r->{'m'};

my $header;
my $footer;
unless (PLAINTEXT) {
    $header = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n<dictionary version=\"0.92\" revision=\"$maxrev\">\n";
    $footer = "</dictionary>";

    # grammemes
    my $grams = "<grammemes>\n";

    $read_g->execute();
    while($r = $read_g->fetchrow_hashref()) {
        $grams .= "    <grammeme parent=\"$r->{'pid'}\"><name>".tidy_xml($r->{'id'})."</name><alias>".tidy_xml(decode('utf8', $r->{'rus_name'}))."</alias><description>".tidy_xml(decode('utf8', $r->{'gram_descr'}))."</description></grammeme>\n";
    }
    $grams .= "</grammemes>\n";

    print $header.$grams;

    # restrictions
    print "<restrictions>\n";
    $read_r->execute();
    while ($r = $read_r->fetchrow_hashref()) {
        my ($left_type, $right_type) = @{$obj_types{$r->{'obj_type'}}};
        print "    <restr type=\"".$restr_types{$r->{'restr_type'}}."\" auto=\"".$r->{'auto'}."\">";
        print "<left type=\"$left_type\">".$r->{'left_gram'}."</left>";
        print "<right type=\"$right_type\">".$r->{'right_gram'}."</right>";
        print "</restr>\n";
    }
    print "</restrictions>\n";
}

# lemmata
print "<lemmata>\n" unless PLAINTEXT;

my $flag = 1;
my $min_lid = 0;

while ($flag) {
    $flag = 0;
    $read_l->execute($min_lid + 1, $min_lid + 10000);
    while($r = $read_l->fetchrow_hashref()) {
        $flag = 1;
        $r->{'rev_text'} =~ s/<\/?dr>//g;
        if (PLAINTEXT) {
            print $r->{'lemma_id'}."\n";
            print rev2text($r->{'rev_text'})."\n";
        } else {
            print '    <lemma id="'.$r->{'lemma_id'}.'" rev="'.$r->{'rev_id'}.'">'.decode('utf8', $r->{'rev_text'})."</lemma>\n";
        }
    }
    $min_lid += 10000;
}

print "</lemmata>\n" unless PLAINTEXT;

unless (PLAINTEXT) {
    # link types
    print "<link_types>\n";

    $read_lt->execute();
    while($r = $read_lt->fetchrow_hashref()) {
        print '<type id="'.$r->{'link_id'}.'">'.tidy_xml($r->{'link_name'})."</type>\n";
    }

    print "</link_types>\n";

    # links
    print "<links>\n";

    $min_lid = 0;
    $flag = 1;

    while($flag) {
        $flag = 0;
        $read_links->execute($min_lid);
        while($r = $read_links->fetchrow_hashref()) {
            $flag = 1;
            print '    <link id="'.$r->{'link_id'}.'" from="'.$r->{'lemma1_id'}.'" to="'.$r->{'lemma2_id'}.'" type="'.$r->{'link_type'}."\"/>\n";
        }
        $min_lid += 10000;
    }

    print "</links>\n";

    print $footer."\n";
}

sub tidy_xml {
    my $arg = shift;
    $arg =~ s/&/&amp;/g;
    $arg =~ s/"/&quot;/g;
    $arg =~ s/'/&apos;/g;
    $arg =~ s/</&lt;/g;
    $arg =~ s/>/&gt;/g;
    return $arg;
}
sub rev2text {
    my $str = shift;

    my @lgr;
    my @fgr;
    my $fstr;
    my $out = '';

    $str =~ /<l(.+)\/l/;
    my $lstr = $1;
    while ($lstr =~ /<g v="([^"]+)"/g) {
        push @lgr, $1;
    }
    while ($str =~ /<f t="([^"]+)">(.*?)<\/f>/g) {
        $out .= uc(decode('utf8', $1))."\t";
        my $fstr = $2;
        @fgr = ();
        while ($fstr =~ /<g v="([^"]+)"/g) {
            push @fgr, $1;
        }
        $out .= join(',', @lgr).' '.join(',', @fgr)."\n";
    }
    return $out;
}
