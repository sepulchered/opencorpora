<?php
require('lib/header.php');
require('lib/lib_annot.php');

if (isset($_GET['q'])) {
    $search = trim(mb_strtolower($_GET['q']));
    $smarty->assign('search', get_search_results($search, isset($_GET['exact_form'])));
    $smarty->display('search.tpl');
} else
    show_error("Не задан поисковый запрос");
log_timing();
