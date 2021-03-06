<?php
require_once('../lib/header_ajax.php');
echo '<?xml version="1.0" encoding="utf-8" standalone="yes"?><root>';
if (isset($_GET['cat'])) {
    $categ = explode('|', $_GET['cat']);
    foreach ($categ as $cat) {
        $cat = str_replace('Категория:', '', $cat);
        if (in_array($cat, array('Опубликовано'))) {
            continue;
        }
        if (preg_match('/^(\d+) (\S+) (\d\d\d\d)$/', $cat, $matches)) {
            echo '<date v="'.sprintf("%02s", $matches[1]).'/'.month_to_number($matches[2]).'"/>';
            echo '<year v="'.$matches[3].'"/>';
        }
        else {
            if(check_for_geo($cat)) {
                echo '<geo v="'.$cat.'"/>';
            }
            else {
                echo '<topic v="'.$cat.'"/>';
            }
        }
    }
}
echo '</root>';

function check_for_geo($s) {
    $res = sql_query("SELECT tag_name FROM book_tags WHERE tag_name = ? LIMIT 1", array('Гео:ВикиКатегория:'.$s));
    return sizeof($res);
}
function month_to_number($s) {
    $months = array(
        'января' => '01',
        'февраля' => '02',
        'марта' => '03',
        'апреля' => '04',
        'мая' => '05',
        'июня' => '06',
        'июля' => '07',
        'августа' => '08',
        'cентября' => '09', //latin 'c'
        'сентября' => '09', //cyrillic 'с'
        'октября' => '10',
        'ноября' => '11',
        'декабря' => '12'
    );
    return $months[$s];
}
