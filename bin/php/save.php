<?php

if (isset($GLOBALS["HTTP_RAW_POST_DATA"])) {

    $fileDir = dirname(__FILE__);
    $upload = '/upload';
    $path = $fileDir . $upload;

	function countFile($dir){
        $num = 0;

		if (is_dir($dir)){
            if ($open = opendir($dir)){
                while(($read = readdir($open)) !== false){
                    if ($read == '.' || $read == '..') continue;
                    if (!is_dir($dir . '/' . $read)){
                        $num += 1;
                    }
                }
            }
        }

        return $num;
	}

    if (!is_dir($path)){
        mkdir($path, 0777);
    }

	$time = time();
    $count = countFile($path);
	$fileName = $time . '_' . $count . '.jpg';
    $filePath = $path . '/' . $fileName;

	$im = $GLOBALS["HTTP_RAW_POST_DATA"];

	$fp = fopen($filePath, 'wb');
	fwrite($fp, $im);
	fclose($fp);

    echo "filename=". $fileName ."&base=". $_SERVER["HTTP_HOST"].dirname($_SERVER["PHP_SELF"]) . $upload . '/';

}