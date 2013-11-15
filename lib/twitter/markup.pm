package Twitter::Markup;
use Dancer;
use strict;
use warnings;

=pod
This has a few helper methods for marking up twitter tweets in html.
=cut

sub markup_tweets {
  if (scalar(@_) < 1) {
    warning "No tweets appear to have been passed in.";
    return ();
  }

  my @text_array = @_;
  my @out_array = ();
  for my $text (@text_array) {
    push(@out_array, markup_tweet($text));
  }
  return @out_array;
}

sub markup_tweet {
  if (scalar(@_) < 1) {
    warning "No text appears to have been passed in.";
    return undef;
  }

  my $text = $_[0];
  $text = markup_first_url($text);
  $text = link_first_at_name($text);
  return $text;
}

sub markup_first_url {
  if (scalar(@_) < 1) {
    warning "No text appears to have been passed in.";
    return undef;
  }

  # This regex is mediocre at best. I'm only catchign urls matching http://t.co/[0-9a-zA-Z].
  # Like link_first_at_name, this doesn't do anything amazing it just links the first url, which seemed good enough for this test app.
  # BUG: I'm pretty sure it has to do with encoding, but for some reason this matches strings like http://t.co/RRnYizPisw) (with the ending ')' char). =\
  my $text = $_[0];
  info $text;
  if ($text =~ m/http:\/\/t.co\/[a-zA-Z0-9]{6,12}/) {
    my $start = $-[0];
    my $end = $+[0];
    my $url = substr($text, $start, $end);
    info "Marking up ".$url;
    $text = substr($text, 0, $start).create_link($url).substr($text, $end, length($text));
  }
  return $text;
}

sub link_first_at_name {
  if (scalar(@_) < 1) {
    warning "No text appears to have been passed in.";
    return undef;
  }

  # This regex isn't perfect and this isn't the best way to do this.
  # I just wanted some sort of links so I am replacing the first at_name
  # eg - this breaks with the current crowdtilt feed. Not 100% sure why but it appears to hate retweets.
  my $text = $_[0];
  info $text;
  if ($text =~ m/\@[a-zA-Z0-9_]{2,15}/) {
    my $start = $-[0];
    my $end = $+[0];
    my $username = substr($text, $start + 1, $end);
    info "Replacing ".$username." with twitter url.";
    $text = substr($text, 0, $start).twitter_url($username).substr($text, $end, length($text));
  }

  # warning "hello \@jon \@dog \@catman, oh boy." =~ m/[@][a-zA-Z_]{2,15}/;

  return $text;
}

sub twitter_url {
  if(scalar(@_) < 1) {
    warning "No username appears to have been provided";
    return "";
  }

  # This shouldn't need cleaned since we only match letters, numbers, and underscores.
  my $username = $_[0];
  return create_link("https://twitter.com/".$username, "@".$username);
}

sub create_link {
  if(scalar(@_) < 1) {
    warning "Neither url or text havent been passed in.";
    return undef;
  } elsif (scalar(@_) < 2) {
    # use the url as the text.
    return create_link($_[0], $_[0])
  }
  my ($url, $link_text) = ($_[0], $_[1]);
  return '<a href="'.$url.'">'.$link_text.'</a>';
}

true;
