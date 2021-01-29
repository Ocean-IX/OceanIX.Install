<?php
function clean($string) {
   $string = str_replace(' ', '-', $string); // Replaces all spaces with hyphens.
   return preg_replace('/[^A-Za-z0-9\-]/', '', $string); // Removes special chars.
}

function bogonASN($string){
	$bogonArray = array(
						"0",
						"23456",
						"64496",
						"64497",
						"64498",
						"64499",
						"64500",
						"64501",
						"64502",
						"64503",
						"64504",
						"64505",
						"64507",
						"64508",
						"64509",
						"64510",
						"64511",
						"64512",
						"64513",
						"64514",
						"64515",
						"64516",
						"64517",
						"64518",
						"64519",
						"64520",
						"64521", 
						"64522", 
						"64523", 
						"64524", 
						"64525", 
						"64526", 
						"64527", 
						"64528", 
						"64529", 
						"64530", 
						"64531", 
						"64532", 
						"64533", 
						"64534", 
						"65535", 
	);
	
	if(in_array($string, $bogonArray)){
		$ret = false;
	}else{
		$ret = true;
	}
	
	return $ret;
}

$ipv4 = false;
$ipv6 = false;

if(!isset($_REQUEST['apiKey'])){
	die('Invalid API Key Found. - Logged.');
}

if(isset($_REQUEST['apiKey'])){
	if(strlen($_REQUEST['apiKey']) != 36){
		$apiUser = false;
		die('Invalid API Key Found. - Logged.');
	}
	$apiString = file_get_contents("../key/api.key");
	if($_REQUEST['apiKey'] == $apiString){
		$apiUser = true;
	}
}
$a = array("sessionName" => "RouteIX Networks Ltd.",
			"sessionEmail" => "connect@routeix.net",
			"ASN" => "AS123456",
			"AS-SET" => "AS-ROUTEIX",
			"sessionAddress" => array("IPv4" => "10.10.6.6", "IPv6" => "2a0a:6040:d6::6"),
			"sessionStack" => "10");
			print_r(json_encode($a));
if($apiUser){
	if(!isset($_REQUEST['string'])){ die("Invalid Request Field"); }
		$bDecode = base64_decode($_REQUEST['string']);
		$jDecode = json_decode($bDecode, true);

		if(!isset($jDecode['sessionName'])){ die("Invalid String Details"); }
		if(!isset($jDecode['sessionEmail'])){ die("Invalid String Details"); }
		if(!isset($jDecode['ASN'])){ die("Invalid String Details"); }
		if(!isset($jDecode['sessionAddress'])){ die("Invalid String Details"); }
		if(!isset($jDecode['sessionStack'])){ die("Invalid String Details"); }
		if(strlen($jDecode['sessionName']) < 4 || strlen($jDecode['sessionName']) > 50){ die("Invalid Session Name"); }
		if(isset($jDecode['AS-SET'])){
		if(strlen($jDecode['AS-SET']) < 3 || strlen($jDecode['AS-SET']) > 30){ die("Invalid AS-SET"); }
		
		$jArray['sessionName'] = clean($jDecode['sessionName']);
		if (filter_var($jDecode['sessionEmail'], FILTER_VALIDATE_EMAIL)) {
			$jArray['sessionEmail'] = $jDecode['sessionEmail'];
		} else {
			die("Invalid Session Email");
		}
		if(!bogonASN($jDecode['ASN'])){
			die("Invalid ASN");
		}else{
			if(is_numeric(str_replace("AS", "", $jDecode['ASN']))){
			$jArray['ASN'] = str_replace("AS", "", $jDecode['ASN']);
			}else{
				die("Invalid ASN");
			}
		}
		if(!is_numeric($jDecode['sessionStack'])){
			die("Invalid Session Stack");
		}elseif($jDecode['sessionStack'] == 4){
			$ipv4 = true;
			//if (filter_var($jDecode['sessionAddress']['IPv4'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4, FILTER_FLAG_NO_PRIV_RANGE, FILTER_FLAG_NO_RES_RANGE)) {
				if (filter_var($jDecode['sessionAddress']['IPv4'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
				$jArray['IPv4'] = $jDecode['sessionAddress']['IPv4'];
			}else{
				die("Invalid IPv4");
			}
		}elseif($jDecode['sessionStack'] == 6){
			$ipv6 = true;
			//if (filter_var($jDecode['sessionAddress']['IPv6'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6, FILTER_FLAG_NO_PRIV_RANGE, FILTER_FLAG_NO_RES_RANGE)) {
				if (filter_var($jDecode['sessionAddress']['IPv6'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
				$jArray['IPv6'] = $jDecode['sessionAddress']['IPv6'];
			}else{
				die("Invalid IPv6");
			}
		}elseif($jDecode['sessionStack'] == 10){
			$ipv4 = true;
			$ipv6 = true;
			//if (filter_var($jDecode['sessionAddress']['IPv4'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4, FILTER_FLAG_NO_PRIV_RANGE, FILTER_FLAG_NO_RES_RANGE)) {
				if (filter_var($jDecode['sessionAddress']['IPv4'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
				$jArray['IPv4'] = $jDecode['sessionAddress']['IPv4'];
			}else{
				die("Invalid IPv4");
			}
			//if (filter_var($jDecode['sessionAddress']['IPv6'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6, FILTER_FLAG_NO_PRIV_RANGE, FILTER_FLAG_NO_RES_RANGE)) {
				if (filter_var($jDecode['sessionAddress']['IPv6'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
				$jArray['IPv6'] = $jDecode['sessionAddress']['IPv6'];
			}else{
				die("Invalid IPv6");
			}
		}else{
			die("Invalid Session Stack");
		}
		
		print_r($jArray);
if($ipv4){
	$v4CFG = "protocol bgp PEER_AS".$jArray['ASN']." from ix_peer
{
	neighbor	as ".$jArray['ASN'].";
	neighbor	".$jArray['IPv4'].";
	description	\"AS".$jArray['ASN']." :: ".$jArray['sessionName']." :: ".$jArray['sessionEmail']."\";
	import filter
	{
		bgp_local_pref = 100;
		if net.len <= PREFIX_MIN && net ~ PREFIX_AS".$jArray['ASN']." then accept;
		if net.len >= PREFIX_MAX then reject;
		reject;
	};

	export filter
	{
		if ((0,0,".$jArray['ASN'].")) ~ bgp_large_community then reject;
		if net.len > PREFIX_MIN then reject;
		accept;
	};
}
		
		";
		$cfgFile = "/app/public/queue/".$jArray['ASN']."_v4.conf";
		if (!file_exists($cfgFile)) {  
		$CFG = fopen($cfgFile, "w") or die("Unable to open file!");
		fwrite($CFG, $v4CFG);
		fclose($CFG);
		}
}

if($ipv6){
	$v6CFG = "protocol bgp PEER_AS".$jArray['ASN']." from ix_peer
{
	neighbor	as ".$jArray['ASN'].";
	neighbor	".$jArray['IPv6'].";
	description	\"AS".$jArray['ASN']." :: ".$jArray['sessionName']." :: ".$jArray['sessionEmail']."\";
	import filter
	{
		bgp_local_pref = 100;
		if net.len <= PREFIX_MIN && net ~ PREFIX_AS".$jArray['ASN']." then accept;
		if net.len >= PREFIX_MAX then reject;
		reject;
	};

	export filter
	{
		if ((0,0,".$jArray['ASN'].")) ~ bgp_large_community then reject;
		if net.len > PREFIX_MIN then reject;
		accept;
	};
}
		
		";
		
		$cfgFile = "/app/public/queue/".$jArray['ASN']."_v6.conf";
		if (!file_exists($cfgFile)) {   
		$CFG = fopen($cfgFile, "w") or die("Unable to open file!");
		fwrite($CFG, $v6CFG);
		fclose($CFG);
		}
}
		$ASFILE = "/app/public/queue/".$jArray['ASN']."_AS-SET";
		if (!file_exists($ASFILE)) {   
		$ASEnter = fopen($ASFILE, "w") or die("Unable to open file!");
		fwrite($ASEnter, $jDecode['AS-SET']);
		fclose($ASEnter);
		}
		}
}

?>
