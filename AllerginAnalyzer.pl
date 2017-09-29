use Mojo::UserAgent;
use Chart::Gnuplot;
use strict;

sub loadTable($);
sub zeroOutYears($);

# Fixes insecure PATH error when starting gnuplot.
$ENV{PATH} = '/bin:/usr/bin';

my @pages = (
	'http://www.rapca.org/datafiles/PollenMoldSum14.htm',
	'http://www.rapca.org/datafiles/PollenMoldSum15.htm',
	'http://www.rapca.org/datafiles/PollenMoldSum16.htm',
	'http://www.rapca.org/datafiles/PollenMoldSum17.htm'
);

my $alternariaChart = new Chart::Gnuplot(
	output => "alternaria-comparison-by-year.ps",
	title  => "Alternaria Comparison by Year",
	xlabel => "Date",
	ylabel => "Count",
    timeaxis  => "x",
    xtics => { labelfmt => "%b %d", rotate => -90},
    xrange => ['4/1/00', '12/1/00']
);

my $ambrosiaChart = new Chart::Gnuplot(
	output => "ambrosia-comparison-by-year.ps",
	title  => "Ambrosia Comparison by Year",
	xlabel => "Date",
	ylabel => "Count",
    timeaxis  => "x",
    xtics => { labelfmt => "%b %d", rotate => -90},
    xrange => ['7/1/00', '12/1/00']
);

my $userAgent = new Mojo::UserAgent;
my @alternariaDataSets;
my @ambrosiaDataSets;

foreach my $page (@pages) {
    print "Reading $page\n";
	my $dom = $userAgent->get($page)->res->dom;
    my $pollenTableRef = loadTable($dom->find('table tr:nth-of-type(3)')->first);
    my $moldTableRef = loadTable($dom->find('table:nth-of-type(2) tr:nth-of-type(2)')->first);
    my ($year) = $moldTableRef->{Date}[0] =~ /(\d\d\d\d)$/;

    zeroOutYears($moldTableRef->{"Date"});
    zeroOutYears($pollenTableRef->{"Date"});
    
	my $alternariaDataSet = new Chart::Gnuplot::DataSet(
		xdata => $moldTableRef->{"Date"},
		ydata => $moldTableRef->{"Alternaria"},
		title => $year,
		style => "linespoints",
        timefmt => "%m/%d/%Y"
	);
    
	my $ambrosiaDataSet = new Chart::Gnuplot::DataSet(
		xdata => $pollenTableRef->{"Date"},
		ydata => $pollenTableRef->{"Ambrosia"},
		title => $year,
		style => "linespoints",
        timefmt => "%m/%d/%Y"
	);
    
    push(@alternariaDataSets, $alternariaDataSet);
    push(@ambrosiaDataSets, $ambrosiaDataSet);
}

print "Plotting alternaria: ", @alternariaDataSets;
$alternariaChart->plot2d(@alternariaDataSets);
$ambrosiaChart->plot2d(@ambrosiaDataSets);

sub loadTable($)
{
	my ($titleRow) = @_;
    
	my %allerginTable; # Allergin Name -> List of counts
	my @allerginNames;
    
    # Get allerginNames
	my @titleElements = $titleRow->children->each;
    foreach my $titleElement (@titleElements) {
        my $allerginName = $titleElement->find('strong')->first->text;
    	push(@allerginNames, $allerginName);
    }
    
    # Initialize lists of counts by allergin name.
    foreach my $allerginName (@allerginNames) {
        # Create an empty array and assign its reference to this allergin name.
        $allerginTable{$allerginName} = [];
    }
    
    # Build %allerginTable from data rows.
	my @dataRows = $titleRow->following('tr')->each;
    foreach my $dataRow (@dataRows) {
        my @allCountsForOneDay = $dataRow->children->map('text')->each;
    	for (my $allerginIndex = 0; $allerginIndex < @allCountsForOneDay; $allerginIndex++) {
            my $allerginName = $allerginNames[$allerginIndex];
            my $countsForAllerginRef = $allerginTable{$allerginName};
            # Add this count to the list for this allergin.
            push(@$countsForAllerginRef, $allCountsForOneDay[$allerginIndex]);
            # Put the reference to the list back in the table. This seems to be necessary.
            $allerginTable{$allerginName} = $countsForAllerginRef;
    	}
    }
    return \%allerginTable;
}

# Accepts a reference to an array containing dates. Changes all the
# years in the dates to 0 so that the data for different years will
# overlap instead of appearing in different places.
sub zeroOutYears($)
{
    my ($dateArrayRef) = @_;
    for (my $i = 0; $i < @$dateArrayRef; $i++) {
        $dateArrayRef->[$i] =~ s/\d\d\d\d$/00/;
    }
}
