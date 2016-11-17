use Mojo::UserAgent;
use Chart::Gnuplot;
use strict;
use Data::Dumper;

sub loadTable($);

# Fix insecure PATH bs when starting gnuplot.
$ENV{PATH} = '/bin:/usr/bin';

my @pages = (
	'http://www.rapca.org/datafiles/PollenMoldSum13.htm',
	'http://www.rapca.org/datafiles/PollenMoldSum14.htm',
	'http://www.rapca.org/datafiles/PollenMoldSum15.htm',
	'http://www.rapca.org/datafiles/PollenMoldSum16.htm'
);

my $chart = new Chart::Gnuplot(
	output => "allergin-graph.ps",
	title  => "Comparison of Allergins by Year",
	xlabel => "Pollen & Mold Spore Count",
	ylabel => "Date",
    timeaxis  => "x"
);

my $userAgent = new Mojo::UserAgent;
my @dataSets = ();

foreach my $page (@pages) {
	my $dom = $userAgent->get($page)->res->dom;
    my $pollenTableRef = loadTable($dom->find('table tr:nth-of-type(3)')->first);
    my $moldTableRef = loadTable($dom->find('table:nth-of-type(2) tr:nth-of-type(2)')->first);

	my $dataSet = new Chart::Gnuplot::DataSet(
		xdata => $moldTableRef->{"Date"},
		ydata => $moldTableRef->{"Alternaria"},
		title => "2013",
		style => "linespoints",
        timefmt => "%m/%d/%Y"
	);

    push(@dataSets, $dataSet);
}

$chart->plot2d($dataSets[3]);

sub loadTable($)
{
	my ($titleRow) = @_;
    
	my %pollenTable  = ();
	my @titles       = ();
    
    # Get titles
	my @titleElements = $titleRow->children->each;
    foreach my $titleElement (@titleElements) {
        my $title = $titleElement->find('strong')->first->text;
    	push(@titles, $title);
    }
    
	my @dailySampleSets = $titleRow->following('tr')->each;
    foreach my $dailySampleSet (@dailySampleSets) {
        my @dailyCounts = $dailySampleSet->children->map('text')->each;
    	for (my $i = 0; $i < @dailyCounts; $i++) {
            if (!$pollenTable{$titles[$i]}) {
                $pollenTable{$titles[$i]} = ();
            }
            my $arrayRef = $pollenTable{$titles[$i]};
            push(@$arrayRef, $dailyCounts[$i]);
            $pollenTable{$titles[$i]} = $arrayRef;
    	}
    }
    return \%pollenTable;
}
