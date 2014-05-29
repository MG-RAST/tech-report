#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Getopt::Long;

sub usage {
  print "texreport2html.pl >>> create HTML version of the MG-RAST technical manual\n";
  print "texreport2html.pl -input <input file> [-insert_includes <boolean>]\n";
}

my $input = "";
my $insert_includes = 0;

GetOptions ( 'input=s' => \$input,
	     'insert_includes=s' => \$insert_includes );

unless ($input) {
  $input = "mg-rast-tech-report.tex";
}

# check for inclusions
if (open(FH, "<$input")) {
  if (open(FT, ">$input.tmp")) {
    while (my $l = <FH>) {
      if ($insert_includes) {
	if (my ($f) = $l =~ /^\\include\{([^\}]+)\}/) {
	  if (open(FI, "<$f.tex")) {
	    while (my $li = <FI>) {
	      print FT $li;
	    }
	    close FI;
	  } else {
	    print STDERR "could not open include file $f.tex: $@\nskipping...\n";
	  }
	}
      }
      print FT $l;
    }
    close FT;
  } else {
    print STDERR "Could not open temp file: $@\n";
    close FH;
    exit 1;
  }
  close FH;
} else {
  print STDERR "Could not open input file: $@\n";
  exit 1;
}

my ($basename) = $input =~ /^(.+)\.tex$/;

# hold the data of the document
  my $doc = { authors => [],
	      affiliations => [],
	      glossary => {},
	      title => "",
	      subtitle => "",
	      version => "",
	      date => "",
	      paragraphs => [],
	      citations => {}
	    };

# check bib file
if (-f $basename.".bib" && open(FH, "<".$basename.".bib")) {
  $doc->{bib} = {};
  my $counter = 1;
  while (my $line = <FH>) {
    chomp $line;

    # start of entry
    if ($line =~ /^\@/) {
      my ($type, $id) = $line =~ /^\@(\w+)\{([\w\.]+)/;
      my $entry = { id => $id,
		    type => lc($type),
		    order => $counter };
      while (my $el = <FH>) {
	chomp $el;
	$el =~ s/``/"/g;
	$el =~ s/^[\s\t]+//;
	if ($el) {
	  my ($key, $val) = $el =~ /^(\w+)\s*=\s*[\{\"]{1}(.+)[\}\"]{1}[,\}]?\s*$/;
	  if ($key) {
	    $val =~ s/\\texttt\{([^\}]+)\}/<span class="mono">$1<\/span>/g;
	    $val = &special($val);
	    $val =~ s/\}$//;
	    $entry->{lc($key)} = $val;
	  }
	} else {
	  $doc->{bib}->{$entry->{id}} = $entry;
	  $counter++;
	  last;
	}
      }
    }

  }
  close FH;
}

# check if we can open the input file
if (open(FH, "<$input.tmp")) {

  # read the document into memory
  my $curr = "";
  while (<FH>) {
    my $line = $_;

    $line = &clean($line);
    next if ($line =~ /^\%/);
    next if ($line =~ /^\}$/);
    next unless (length $line);

    my ($cmd) = $line =~ /^\\(\w+)/;
    if ($cmd) {
	if ($cmd eq "author") {
	    my ($affils, $name) = $line =~ /^\\author\[(.+)\]\{(.+)\}$/;
	    push(@{$doc->{authors}}, { name => $name, affils => [ split(/,/, $affils) ] });
	} elsif ($cmd eq "affil") {
	    my ($num, $name) = $line =~ /^\\affil\[(\d+)\]\{(.+)\}$/;
	    push(@{$doc->{affiliations}}, "<sup>$num</sup>$name");
	} elsif ($cmd eq "date") {
	    my ($date) = $line =~ /^\\date\{(.+)\}$/;
	    $doc->{date} = $date;
	} elsif ($cmd eq "title") {
	    my $title = <FH>;
	    chomp $title;
	    $title =~ s/\\+//;
	    $doc->{title} = $title;
	    my $subtitle = <FH>;
	    chomp $subtitle;
	    $subtitle =~ s/\\+//;
	    $doc->{subtitle} = $subtitle;
	    my $version = <FH>;
	    chomp $version;
	    $doc->{version} = $version;
	} elsif ($cmd eq "dictentry") {
	    my ($key, $val) = $line =~ /^\\dictentry\{(.+)\}\{(.+)\}$/;
	    $doc->{glossary}->{$key} = $val;
	} elsif ($cmd eq "chapter") {
	    my ($text) = $line =~ /^\\chapter\{(.+)\}$/;
	    push(@{$doc->{paragraphs}}, { type => "chapter",
					  text => $text });
	} elsif ($cmd eq "section") {
	    my ($text) = $line =~ /^\\section\*?\{(.+)\}$/;
	    push(@{$doc->{paragraphs}}, { type => "section",
					  text => $text });
	  } elsif ($cmd eq "subsection") {
	    my ($text) = $line =~ /^\\subsection\*?\{(.+)\}/;
	    push(@{$doc->{paragraphs}}, { type => "subsection",
					  text => $text });
	  } elsif ($cmd eq "subparagraph") {
	    my ($text) = $line =~ /^\\subparagraph\*?\{(.+)\}/;
	    push(@{$doc->{paragraphs}}, { type => "subparagraph",
					  text => $text });
	  } elsif ($cmd eq "subsubsection") {
	    my ($text) = $line =~ /^\\subsubsection\*?\{(.+)\}/;
	    push(@{$doc->{paragraphs}}, { type => "subparagraph",
					  text => $text });
	  } elsif ($cmd eq "begin" && $line =~ /figure/) {
	    my $image = { type => "image" };
	    while ($line !~ /\\end\{figure\*?\}/) {
		$line = <FH>;
		$line = &clean($line);

		if ($line =~ /\\includegraphics/) {
		    my ($width, $img) = $line =~ /\[width=([\d\w]+)\]{(.+)\}/;
		    $image->{path} = $img;
		    $image->{width} = $width;
		} elsif ($line =~ /\\label/) {
		    my ($label) = $line =~ /\{(.+)\}/;
		    push(@{$doc->{paragraphs}}, { "type" => "label",
						  "text" => $label });
		} elsif ($line =~ /\\caption/) {
		    chomp $line;
		    my ($cap) = $line =~ /^\\caption\{(.+)$/;
		    while ($line !~ /\\end\{figure\*?\}/) {
			$line = <FH>;
			$line = &clean($line);
			if ($line =~ /\\label/) {
			  my ($label) = $line =~ /\{(.+)\}/;
			  push(@{$doc->{paragraphs}}, { "type" => "label",
							"text" => $label });
			} else {
			  $cap .= $line;
			}
		    }
		    $cap =~ s/}\\end\{figure\*?\}//;
		    $image->{caption} = $cap;
		}
	    }
	    push(@{$doc->{paragraphs}}, $image);
	} elsif ($cmd eq "begin" && $line =~ /enumerate/) {
	    my $items = [];
	    my $key = "";
	    my $value = "";
	    while ($line !~ /\\end\{enumerate\}/) {
		$line = <FH>;
		$line = &clean($line);
		next unless $line;
		if ($line =~ /\\item/) {
		    if ($key) {
			push(@$items, [ $key, $value ]);
			$value = "";
		    }
		    ($key) = $line =~ /\\item (.+)/;
		} elsif ($line !~ /^\\/) {
		  $value .= $line;
		} elsif ($line =~ /\\begin\{verbatim\}/) {
		  $value .= "<pre>";
		} elsif ($line =~ /\\end\{verbatim\}/) {
		  $value .= "</pre>";
		}
	      }
	    push(@{$doc->{paragraphs}}, { type => "enumerate",
					  items => $items } );
	  } elsif ($cmd eq "begin" && $line =~ /itemize/) {
	    my $items = [];
	    my $key = "";
	    my $value = "";
	    while ($line !~ /\\end\{itemize\}/) {
	      $line = <FH>;
	      $line = &clean($line);
	      next unless $line;
	      if ($line =~ /\\item/) {
		if ($key) {
		  push(@$items, [ $key, $value ]);
		  $value = "";
		}
		($key) = $line =~ /\\item (.+)/;
	      } elsif ($line !~ /^\\/) {
		$value .= $line;
	      } elsif ($line =~ /\\begin\{verbatim\}/) {
		$value .= "<pre>";
	      } elsif ($line =~ /\\end\{verbatim\}/) {
		$value .= "</pre>";
	      }
	    }
	    push(@{$doc->{paragraphs}}, { type => "itemize",
					  items => $items } );
	  } elsif ($cmd eq "begin" && $line =~ /table/) {
	    my $table = { rows => [] };
	    while ($line !~ /\\end\{table\}/) {
	      $line = <FH>;
	      $line = &clean($line,1);
	      next unless $line;
	      if ($line =~ /\\caption/) {
		( $table->{caption} ) = $line =~ /\\caption\{([^\}]+)\}/;
	      } elsif($line =~ /\\label/) {
		my ($label) = $line =~ /\\label\{(.+)\}/;
		push(@{$doc->{paragraphs}}, { type => "label", text => $label });
	      } elsif ($line =~ /\\begin\{tabular\}/) {
		my ($cols) = $line =~ /\\begin\{tabular\}\{([^\}]+)\}/;
		$table->{alignment} = [ split(/\|/, $cols) ];
	      } elsif ($line =~ /\\\\/) {
		chop $line; chop $line;
		my @row = split(/\&/, $line);
		if ($line =~ /&$/) {
		  push(@row, "&nbsp;");
		}
		push(@{$table->{rows}}, \@row);
	      }
	    }
	    push(@{$doc->{paragraphs}}, { type => "table", table => $table } );
	  } elsif ($cmd eq "begin" && $line =~ /verbatim/) {
	    my $text = "";
	    $line = <FH>;
	    while ($line !~ /\\end\{verbatim\}/) {
	      $text .= $line;
	      $line = <FH>;
	    }
	    push(@{$doc->{paragraphs}}, { type => "verbatim",
					  text => $text } );
	  } elsif ($cmd eq "label") {
	    my ($label) = $line =~ /\\label\{(.+)\}/;
	    push(@{$doc->{paragraphs}}, { type => "label",
					  text => $label } );
	  } elsif ($cmd eq "textbf") {
	    my ($bold, $text) = $line =~ /\\textbf\{(.+)\}(.+)/;
	    push(@{$doc->{paragraphs}}, { type => "bold",
					  bold => $bold,
					  text => $text } );
	  } elsif ($cmd eq "url") {
	    my ($url) = $line =~ /\\url\{(.+)\}/;
	    push(@{$doc->{paragraphs}}, { type => "text",
					  text => "<a href='".$url."' target=_blank>".$url."</a>" } );
	  }
    } elsif ($line !~ /^\\/) {
      push(@{$doc->{paragraphs}}, { type => "text",
				    text => $line } );
    }
    
  }
  close FH;
  unlink "$input.tmp";
  
} else {
  print "ERROR: Could not open tex file ($input) - $@\n";
  exit 1;
}

# create the html
my $html = qq~
<!DOCTYPE html>
<html>
  <head>
    <title>~.$doc->{title}.qq~ - ~.$doc->{subtitle}.qq~</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" type="text/css" href="css/bootstrap.min.css">
    <link rel="stylesheet" type="text/css" href="css/bootstrap-responsive.min.css">
    <script src="js/jquery.min.js"></script>
    <style>
.docs-sidenav > li:first-child > a {
    border-radius: 6px 6px 0 0;
}
.docs-sidenav > li:last-child > a {
    border-radius: 0 0 6px 6px;
}
.docs-sidenav > li > a {
    border: 1px solid #E5E5E5;
    display: block;
    margin: 0 0 -1px;
    padding: 8px 14px;
}
.docs-sidenav > .active > a {
    border: 0 none;
    box-shadow: 1px 0 0 rgba(0, 0, 0, 0.1) inset, -1px 0 0 rgba(0, 0, 0, 0.1) inset;
    padding: 9px 15px;
    position: relative;
    text-shadow: 0 1px 0 rgba(0, 0, 0, 0.15);
    z-index: 2;
}
.docs-sidenav > li > a:hover {
    background-color: #F5F5F5;
}
.glossary {
    cursor: help;
}
.footnote {
    cursor: context-menu;
}
blockquote small {
    color: black;
}
.mono {
    font-family: monospace;
}
.math {
    font-size: 17px;
    text-align: center;
    margin-top: 20px;
    margin-bottom: 20px;
}
.sigma {
    font-size: 22px;
}
pre {
    margin-top: 20px;
    margin-bottom: 20px;
}
    </style>
  </head>
  <body style="padding-bottom: 100px; padding-top: 60px;" data-target=".docs-sidebar" data-spy="scroll" data-offset="62">
    <div style="margin-top: -60px;" class="visible-phone visible-tablet hidden-desktop"></div>
    <div class="navbar navbar-inverse navbar-fixed-top">
      <div class="navbar-inner">
	<div class="container" style="width: 100%; padding-left: 10px;">
          <img src="Images/MGRAST_logo.png" style="float: left; background: black; margin-left: -10px; height: 55px;">
    	  <a class="brand" href="#" style="color: white; cursor: default; margin-top: 8px; margin-left: 30px;">~.$doc->{title}.qq~</a>
	</div>
      </div>
    </div>
    <div class="container">
      <div class="row">
        <div class="span3 docs-sidebar hidden-phone hidden-tablet">
          <ul class="nav nav-list docs-sidenav affix span3" style="top: 70px; left: 50px; background-color: #FFFFFF; border-radius: 6px; box-shadow: 0 1px 4px rgba(0, 0, 0, 0.067); padding: 0;">
~;

# navigation
my $counter = 0;
foreach my $p (@{$doc->{paragraphs}}) {
  if ($p->{type} eq "chapter") {
    $html .= '<li><a href="#navitem_'.$counter.'" onclick="location.hash=\'#navitem_'.$counter.'\';window.scrollBy(0,-60);return false;">'.$p->{text}.'</a></li>';
    $counter++;
  }
}

if ($doc->{bib}) {
  $html .= '<li><a href="#bibliography" onclick="location.hash=\'#bibliography\';window.scrollBy(0,-60);return false;">Bibliography</a></li>';
}

$counter = 0;
$html .= qq~</ul></div>
        <div class="span9">
          <h1 style="text-align: center;">~.$doc->{title}.qq~</h1><h3 style="text-align: center;">~.$doc->{subtitle}.qq~</h3><p>~.join(" ", @{$doc->{authors}}).qq~</p><p style='float: right;'>~.join(" ", @{$doc->{affiliations}}).qq~</p>~;

# paragraphs
my $first = 1;
foreach my $p (@{$doc->{paragraphs}}) {
  if ($p->{type} eq "chapter") {
    unless ($first) {
      $html .= "</section>";
    }
    $html .= "<section id='navitem_".$counter."'><h2>".$p->{text}."</h2>";
    $counter++;
    $first = 0;
  } elsif ($p->{type} eq "section") {
    $html .= "<h3>".$p->{text}."</h3>";
  } elsif ($p->{type} eq "subsection") {
    $html .= "<h4>".$p->{text}."</h4>";
  } elsif ($p->{type} eq "subparagraph") {
    $html .= "<h5>".$p->{text}."</h5>";
  } elsif ($p->{type} eq "text") {
    $html .= "<p style='clear: both;'>".$p->{text}."</p>";
  } elsif ($p->{type} eq "itemize") {
    $html .= "<ul>";
    for my $item (@{$p->{items}}) {
      $html .= "<li>";
      my $hyphen = 0;
      if ($item->[0] =~ /--$/) {
	$item->[0] =~ s/--$//;
	$hyphen = 1;
      }
      $html .= $item->[0];
      if ($item->[1]) {
	if ($item->[0] =~ /--$/) {
	  $html .= " &#150; ";
	} else {
	  $html .= "<br>";
	}
	$html .= $item->[1];
      }
      $html .= "</li>";
    }
    $html .= "</ul>";
  } elsif ($p->{type} eq "enumerate") {
    $html .= "<ol>";
    for my $item (@{$p->{items}}) {
      $html .= "<li>";
      my $hyphen = 0;
      if ($item->[0] =~ /--$/) {
	$item->[0] =~ s/--$//;
	$hyphen = 1;
      }
      $html .= $item->[0];
      if ($item->[1]) {
	if ($item->[0] =~ /--$/) {
	  $html .= " &#150; ";
	} else {
	  $html .= "<br>";
	}
	$html .= $item->[1];
      }
      $html .= "</li>";
    }
    $html .= "</ol>";
  } elsif ($p->{type} eq "table") {
    $html .= "<div style='text-align: center;'><table class='table table-bordered'>";
    if ($p->{table}->{caption}) {
      $html .= "<h5>".$p->{table}->{caption}."</h5>";
    }
    my $firstrow = shift(@{$p->{table}->{rows}});
    $html .= "<tr>";
    for (my $i=0; $i<scalar(@$firstrow); $i++) {
      my $align = "";
      if ($p->{table}->{alignment}) {
	  $align = " style='text-align: ".($p->{table}->{alignment}->[$i] ? ($p->{table}->{alignment}->[$i] eq "l" ? "left" : ($p->{table}->{alignment}->[$i] eq "r" ? "right" : "center")) : "left")."'";
      }
      $html .= "<th$align>".$firstrow->[$i]."</th>";
    }
    $html .= "</tr>";
    foreach my $row (@{$p->{table}->{rows}}) {
      $html .= "<tr>";
      for (my $i=0; $i<scalar(@$row); $i++) {
	my $align = "";
	if ($p->{table}->{alignment}) {
	  $align = " style='text-align: ".($p->{table}->{alignment}->[$i] ? ($p->{table}->{alignment}->[$i] eq "l" ? "left" : ($p->{table}->{alignment}->[$i] eq "r" ? "right" : "center")) : "left")."'";
	}
	$html .= "<td$align>".$row->[$i]."</td>";
      }
      $html .= "</tr>";
    }
    $html .= "</table></div>";
  } elsif ($p->{type} eq "verbatim") {
    $html .= "<pre>".$p->{text}."</pre>";
  } elsif ($p->{type} eq "image") {
    next unless $p->{path};
    if ($p->{path} !~ /\.\w+$/) {
      $p->{path} .= ".png";
    }
    $html .= "<div style='text-align: center; margin-bottom: 10px;'><img style='width: ".$p->{width}."; cursor: pointer;' onclick='window.open(\"".$p->{path}."\");' src='".$p->{path}."'></div>";
    $html .= '<blockquote><p><small>'.$p->{caption}.'</small></p></blockquote>';
  } elsif ($p->{type} eq "label") {
    $html .= "<a name='".$p->{text}."'></a>";
  } 
}

$html .= "</section>";

# Bibliography
if ($doc->{bib}) {
  $html .= "<section id='bibliography'><h2>Bibliography</h2><table>";
  
  my $ordered = [];
  foreach my $key (keys(%{$doc->{bib}})) {
    my $entry = $doc->{bib}->{$key};
    $ordered->[$entry->{order}] = $entry;
  }
  
  foreach my $entry (@$ordered) {
    next unless ($entry->{type});

    # remove {}
    foreach my $key (keys(%$entry)) {
      $entry->{$key} =~ s/[\{\}]//g;
    }

    # parse author list
    my $authors = [];
    foreach my $author (split(/ and /, $entry->{author})) {
      my ($last, $first) = split(/, /, $author);
      push(@$authors, ($first ? "$first " : "") . $last);
    }
    $authors = join(", ", @$authors);
    $authors =~ s/(.*), (.*)/$1 and $2/;

    # check different publication types
    if (lc($entry->{type}) eq "article") {
      $html .= "<tr><td style='vertical-align: top; width: 30px;'><a name='citation_".$entry->{order}."' style='color: black;'>[".$entry->{order}."]</a></td><td>".$authors.". ".$entry->{title}.". <i>".$entry->{journal}."</i>, ".($entry->{volume} ? $entry->{volume}. ($entry->{pages} ? ":" : "") : "").($entry->{pages} ? $entry->{pages} : "").($entry->{year} ? ", ".$entry->{year} : "").".</td></tr>";
    } elsif (lc($entry->{type}) eq "misc") {
      $entry->{url} =~ s/\\//g;
      $html .= "<tr><td style='vertical-align: top; width: 30px;'><a name='citation_".$entry->{order}."' style='color: black;'>[".$entry->{order}."]</a></td><td>".$authors.". ".$entry->{title}.($entry->{year} ? ", ".$entry->{year}.". " : "").($entry->{note} ? $entry->{note}.". " : "").($entry->{url} ? " <a href='".$entry->{url}."' target=_blank>".$entry->{url}."</a>" : "")."</td></tr>";
    } elsif (lc($entry->{type}) eq "book") {
      $html .= "<tr><td style='vertical-align: top; width: 30px;'><a name='citation_".$entry->{order}."' style='color: black;'>[".$entry->{order}."]</a></td><td>".$authors.". <i>".$entry->{title}."</i>. ".$entry->{publisher}.", ".$entry->{year}.".</td></tr>";    
    } elsif (lc($entry->{type}) eq "unpublished") {
      $html .= "<tr><td style='vertical-align: top; width: 30px;'><a name='citation_".$entry->{order}."' style='color: black;'>[".$entry->{order}."]</a></td><td>".$authors.". <i>".$entry->{title}."</i>. ".($entry->{month} ? $entry->{month}." " : "").$entry->{year}.". ".($entry->{note} ? $entry->{note}."." : "")."</td></tr>";    
    } elsif (lc($entry->{type}) eq "inproceedings") {
      $html .= "<tr><td style='vertical-align: top; width: 30px;'><a name='citation_".$entry->{order}."' style='color: black;'>[".$entry->{order}."]</a></td><td>".$authors.". ".$entry->{title}.". In <i>".$entry->{booktitle}."</i>, ".$entry->{year}.".</td></tr>";    
    }
  }
  $html .= "</table></section>";
}

# script
$html .= qq~
        </div>
      </div>
    </div>
    <script src="js/bootstrap.min.js"></script>
    <script>
    jQuery('#docs-sidebar').scrollspy();
    jQuery('.glossary').each(function(i){
      jQuery(this).popover( { trigger: "hover" } );
    });
    jQuery('.footnote').each(function(i){
      jQuery(this).popover( { trigger: "hover" } );
    });
    </script>
  </body>
</html>
~;

if (open(FH, ">".$basename.".html")) {
  print FH $html;
  close FH;
} else {
  print "ERROR: Could not open output file - $@\n";
  exit 1;
}

print "done.\n";

sub clean {
  my ($line,$istable) = @_;
  
  chomp $line;
  $line =~ s/^\s+//;
  my $scroll = ' onclick="location.hash=this.getAttribute(\'href\');window.scrollBy(0,-60);return false;"';
  $line =~ s/\\ref\{(\w+\:)([^\}]+)\}/<a href="#$1$2\"$scroll>$2<\/a>/g;
  $line =~ s/\\ref\{([^\}]+)\}/<a href="#$1\"$scroll>$1<\/a>/g;
  $line =~ s/\\url\{([^\}]+)\}/<a href="$1\" target=_blank>$1<\/a>/g;
  $line =~ s/\\texttt\{([^\}]+)\}/<span class="mono">$1<\/span>/g;
  $line =~ s/\\textit\{([^\}]+)\}/<i>$1<\/i>/g;
  $line =~ s/\\textsuperscript\{([^\}]+)\}/<sup>$1<\/sup>/g;
  $line =~ s/\\textbf\{([^\}]+)\}/<b>$1<\/b>/g;
  $line =~ s/\\begin\{small\}//g;
  $line =~ s/\\end\{small\}//g;
  $line =~ s/\\textrm\{([^\}]+)\}/$1/g;
  $line =~ s/\{\\bf ([^\}]+)\}/<b>$1<\/b>/g;
  $line =~ s/--/&hyphen;/g;
  $line =~ s/\$(.)\$/$1/g;
  $line =~ s/``/"/g;
  $line =~ s/\\bfseries//g;
  $line =~ s/\\noindent//g;
  $line =~ s/\$(\d+)\$/$1/g;
  $line =~ s/\$(\d+)\^\{([^\}]+)\}\$/$1<sup>$2<\/sup>/g;
  $line =~ s/\$(\w)_(\w)\$/$1<sub>$2<\/sub>/g;
  $line =~ s/\$\{([^\}]+)\}\$/<b>$1<\/b>/g;
  
  if ($line =~ /\% author name/) {
    my ($author) = $line =~ /\{([^\}]+)\}/;
    push(@{$doc->{authors}}, $author);
    $line = "";
  }

  if ($line =~ /\% affiliation/) {
    my ($affiliation) = $line =~ /\{([^\}]+)\}/;
    push(@{$doc->{affiliations}}, $affiliation);
    $line = "";
  }

  if (! $istable) {
    $line =~ s/\\\\.*//;
  }
  $line =~ s/\{\\large([^\}]+)\}/<h4>$1<\/h4>/g;
  $line =~ s/([^\\]{1})\%.+/$1/;

  $line = &special($line);
  my ($math) = $line =~ /\$\$(.+)\$\$/;
  if ($math) {
    $math = &math($math);
    $line =~ s/\$\$(.+)\$\$/$math/;
  }

  if ($line =~ /\{\\Huge([^\}]+)\}/) {
    $line = "";
    if ($doc->{title}) {
      $doc->{subtitle} .= $1;
    } else {
      $doc->{title} = $1;
    }
  }

  # this should not be in the document!
  $line =~ s/\(\\date\{\\today\}\)//g;
  $line =~ s/\\hspace\{\d+\s*\w+\}/ /g;

  my ($gid) = $line =~ /\\gls\{([^\}]+)\}/;
  if ($gid) {
    my $title = $gid;
    $title =~ s/'/&#39;/g;
    $title =~ s/"/&#34;/g;
    my $content = $doc->{glossary}->{$gid};
    $content =~  s/'/&#39;/g;
    $content =~ s/"/&#34;/g;
    my $popover = '<span class="glossary" data-toggle="popover" data-title="'.$title.'" data-content="'.$content.'">'.$gid.'<sup>[?]</sup></span>';
    $line =~ s/\\gls\{([^\}]+)\}/$popover/g;
  }
  my ($foot) = $line =~ /\\footnote\{([^\}]+)\}/;
  if ($foot) {
    $foot =~ s/'/&#39;/g;
    $foot =~ s/"/&#34;/g;
    my $popover = '<span class="footnote" data-toggle="popover" data-content="'.$foot.'"><sup>[1]</sup></span>';
    $line =~ s/\\footnote\{([^\}]+)\}/$popover/g;
  }
  $line =~ s/\\\$/\$/g;
  $line =~ s/\\\%/\%/g;
  if ($doc->{bib}) {
    while ($line =~ /\\cite/) {
      my ($id) = $line =~ /\\cite\{([^\}]+)\}/;
      my $citation = "";
      my $entry = $doc->{bib}->{$id};
      if ($entry) {
	$citation = '<a href="#citation_'.$entry->{order}.'" onclick="location.hash=this.getAttribute(\'href\');window.scrollBy(0,-60);return false;">['.$entry->{order}.']</a>';
      }
      $line =~ s/\\cite\{[^\}]+\}/$citation/;
    }
  }
  
  return $line;
}

sub special {
  my ($line) = @_;

  $line =~ s/\\_/_/g;
  $line =~ s/\\#/#/g;
  $line =~ s/\{\\"(\w)\}/&$1uml;/g;
  $line =~ s/\{\\'(\w)\}/&$1acute;/g;
  $line =~ s/\\"\{(\w)\}/&$1uml;/g;
  $line =~ s/\$(\d+)\^(\d+)\$/$1<sup>$2<\/sup>/g;
  $line =~ s/\{?\$(\d*)\\(\w+)\$\}?/$1&$2;/g;
  while (my ($math) = $line =~ /\\begin\{math\}(.*?)\\end\{math\}/) {
    $math = &math($math, 1);
    $line =~ s/\\begin\{math\}(.*?)\\end\{math\}/$math/;
  }

  return $line;
}

sub math {
  my ($line, $nodiv) = @_;

  $line =~ s/\\,//g;
  $line =~ s/\\frac\{([^\}]+)\}\{([^\}]+)\}/$1 \/ $2/g;
  $line =~ s/\\sum/<sub><span class="sigma">&Sigma;<\/span><\/sub>/g;
  $line =~ s/\\log/log/g;
#  $line =~ s/_(\w)/<sub>$1<\/sub>/g;
  $line =~ s/\^\{([^\}]+)\}/<sup>$1<\/sup>/g;
  $line =~ s/\\sigma/&sigma;/g;
  $line =~ s/\\mu/&mu;/g;

  return $nodiv ? $line : "<div class='math'>".$line."</div>";
}
