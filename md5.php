<?php
/**
 * ESP application updater
 * Ver. 1.0
 *
 * Gianluigi Cosari - gianluigi@cosari.it
 * October 2016
 *
 *
 */

define("AF_DIR", "appfiles/");

$data = array();
$hash_str = "";

$files = scandir(AF_DIR, SCANDIR_SORT_ASCENDING);

foreach($files as $entry) {
	if ($entry != "." && $entry != "..") {
		$md5 = md5_file(AF_DIR . $entry);
		$data[$entry] = $md5;
		$hash_str .= $entry . $md5;
	}
}

$jlist = json_encode($data);
$group_hash = md5($hash_str);

file_put_contents("list.json", $jlist);

echo $group_hash;
?> 