#!/bin/perl -w
#
# Scrape therauri into textfiles from the soon-to-be-obsolete VESA service (http://vesa.lib.helsinki.fi/)
#
# Version: 1.0
# Created:
# 14.5.2015
#
# Author: Tuomo Virolainen (tuomo.virolainen@helsinki.fi)

use strict;
use utf8;
use List::MoreUtils qw(uniq);
use pQuery;
binmode STDOUT, ":utf8";
$| = 1;

&scraper();

sub scraper
{
	my $beg_time = time;
	my $URL;

	print "Select a thesaurus to be scraped: \n 1) YSA \n 2) Allärs \n 3) MUSA/Cilla\n";
	chomp(my $choice = <STDIN>);

	if ($choice == 1)
		{
			$URL = "http://vesa.lib.helsinki.fi/ysa/aakkoset/";
		}
		
		elsif ($choice == 2) 
		{
			$URL = "http://vesa.lib.helsinki.fi/allars/aakkoset/";
		}
		
		elsif ($choice == 3) 
		{
			$URL = "http://vesa.lib.helsinki.fi/musa/aakkoset/";
		}
		
		else 
		{ 
			die "Choice not recognized, quitting.\n"; 
		}

	print "Enter filename: ";
	chomp(my $file = <STDIN>);

	if (-e $file)
	{
		print "\nFile $file exists. Overwrite? (y/n): ";
		chomp(my $overwrite = <STDIN>);
		$overwrite eq "n" ? return 0 : print "\n"; 
	}

	my @thesaurus_URLS;

	pQuery($URL) 
		->find("a")
		->each(sub {
			my $ending;
			$ending = pQuery($_)->text;
			if ($ending =~ m/.html/i) {
				push @thesaurus_URLS, $URL . $ending;
				}
			});

	my @thesaurus;

	open FILE, ">:utf8", $file || die "File cannot be written: $!\n";

	print "Retrieving headings...\n";
	my $thesaurus_length = @thesaurus_URLS;
	print "|" . (" " x $thesaurus_length) . "|\n";
	print "|";
	foreach (@thesaurus_URLS) 
	{
		print ".";
		pQuery($_)
			->find("a")
			->each(sub 
			{
				my $tulos; 
				$tulos = ($_->getAttribute( 'target' ));
				if ($tulos && $tulos eq 'tulos') 
				{
					push @thesaurus, pQuery($_)->text;
				}
			})
	}

	print "|\n";
	print "Organizing headings...\n";

	@thesaurus = sort(@thesaurus);
	@thesaurus = uniq(@thesaurus);
	@thesaurus = grep(/\S/, @thesaurus);

	print "Writing headings to file...\n";

	foreach (@thesaurus) 
	{
		print FILE "$_\n";
	}

	my $thesaurus_headings = @thesaurus;
	chomp($thesaurus_headings);
	close(FILE);
	my $end_time = time;
	my $time = ($end_time - $beg_time);
	print "$thesaurus_headings headings written in file $file in $time seconds.\n";
	return @thesaurus;
}