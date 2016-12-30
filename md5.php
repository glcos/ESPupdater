<?php
/**
 * ESP application updater
 * Ver. 1.3
 *
 * Gianluigi Cosari - gianluigi@cosari.it
 * December 2016
 *
 *
 */

define("AF_DIR", "appfiles/");

$data = array();
$hash_str = "";

$appName = filter_input(INPUT_GET, "a", FILTER_SANITIZE_STRING);

if (isset($appName)) {
	// Sanitize input, remove unwanted characters
	$unallowed = array("/", "\\", ".");
	$appName = str_replace($unallowed, "", $appName);
	$fullpath = AF_DIR . $appName . "/";
} else {
	$fullpath = AF_DIR;
}

if (!is_dir($fullpath)) {
	echo "*error* directory not found";
	exit;
}

$files = scandir($fullpath, SCANDIR_SORT_ASCENDING);

if (count($files) < 3) {
	echo "*error* no files found";
	exit;	
}

foreach($files as $entry) {
	if ($entry != "." && $entry != "..") {
		$md5 = md5_file($fullpath . $entry);
		$data[$entry] = $md5;
		$hash_str .= $entry . $md5;
	}
}

$jlist = json_encode($data);
$group_hash = md5($hash_str);

file_put_contents($appName . ".json", $jlist);

echo $group_hash;
?> 