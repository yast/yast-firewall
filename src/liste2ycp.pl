#!/usr/bin/perl -w -i.bak

$insertcode="print";

open IN,"<liste";
while(<IN>)
{
	($service,$default)=split(/\s+/);
	push @services,$service;
	push @defaults,$default;
}
close IN ;


while(<>)
{
	if(/<AUTOCODE READ>/)
	{
		$insertcode="read";
		print;
	}
	elsif(/<AUTOCODE WRITE>/)
	{
		$insertcode="write";
		print;
	}
	elsif(/<\/AUTOCODE>/)
	{
		$insertcode="print";
	}

	if($insertcode eq "print")
	{
		print;
	}
	elsif($insertcode eq "read")
	{
		$insertcode="donothing";
		@myservices = @services;
		@mydefaults = @defaults;
		while(@myservices)
		{
			$service = pop @myservices;
			$default = pop @mydefaults;
			print "    string $service = SCR::Read(.sysconfig.SuSEfirewall2.$service);\n";
			print "    if( $service == nil ) $service = $default;\n";
			print "    change(settings,\"$service\",$service);\n";
			print "\n";
		}
	}
	elsif($insertcode eq "write")
	{
		$insertcode="donothing";
		@myservices = @services;
		@mydefaults = @defaults;
		while(@myservices)
		{
			$service = pop @myservices;
			$default = pop @mydefaults;
			print "    string $service = lookup(settings,\"$service\",$default);\n";
			print "    ret = SCR::Write(.sysconfig.SuSEfirewall2.$service, $service);\n";
			print "\n"
		}
	}
}
