package Twitter::Client;
use Dancer;
use strict;
use warnings;
use Net::Twitter;
use Data::Dumper;
use Encode qw(decode encode);

=pod
This has a few helper methods for reaching the twitter API.
=cut

my $TWITTER_CONSUMER_KEY = 'X7yOOilXAvacL8gemR7SGg';
my $TWITTER_CONSUMER_SECRET = 'BXqUqj4oEtNuPtWBlpQS9ojXOVUuh7sJCJwxih4OLM';
my $CLIENT = undef;

sub lookup_users {
  if (scalar(@_) < 1) {
    warning "No user ids appear to have been passed in.";
    return (); # this is possible with no intersection so we shoudl just return an empty array.
  }

  my @ids = @_;
  my @users = ();
  # API caps at 100 per req so we need to make sure this is split to groups of 100.
  for (my $i = 0; $i < scalar(@ids); $i += 3) {
    # inclusive so +99 here, and +100 above.
    my @id_subset = @ids[$i..($i+2)];
    @id_subset = grep defined, @id_subset;
    my @temp_users = lookup_users_limited(@id_subset);
    push(@users, @temp_users);
  }

  return @users;
}

sub lookup_users_limited {
  if (scalar(@_) < 1) {
    warning "No user ids were passed in.";
    return ();
  }

  my @ids = @_;
  my $twitter_client = twitter_client();

  my $users = $twitter_client->lookup_users({ user_id => join(",", @ids) });
  my @results = ();
  for my $user (@$users) {
    push(@results, {
      'screen_name' => $$user{'screen_name'},
      'profile_image_url' => $$user{'profile_image_url'}
    });
  }

  return @results;
}

sub get_friends {
  if (scalar(@_) < 1) {
    warning "No username appears to have been passed in.";
    return undef;
  }
  my $screen_name = $_[0];
  my $twitter_client = twitter_client();

  unless (defined $twitter_client) {
    error "Something went wrong initializing the Twitter client.";
    return undef;
  }

  my @res = $twitter_client->friends_ids({ screen_name => $screen_name });
  # I am likely doing something wrong that requires me to use a $friend_ids variable here, but it works so ill come back to it after my first pass.
  my $friend_ids = $res[0]{'ids'};
  return @$friend_ids;
}

sub get_tweets {
  if (scalar(@_) < 1) {
    warning "No username appears to have been passed in.";
    return undef;
  }
  my $screen_name = $_[0];
  my $twitter_client = twitter_client();

  unless (defined $twitter_client) {
    error "Something went wrong initializing the Twitter client.";
    return undef;
  }

  my @text_array = ();
  my $tweets = $twitter_client->user_timeline({ screen_name => $screen_name });
  for my $tweet (@$tweets) {
    # This $$ and @$ crap is really annoying. I'm hoping I am doing something wrong, but for now it works so I'll ignore it.
    if (exists $$tweet{'text'}) {
      # The twitter API seems to return some really shitty data, that or Perl really just hates it. I try to encode in utf8 here but I'm 99% sure there are still issues.
      my $text = $$tweet{'text'};
      utf8::encode($text);
      push(@text_array, $text);
    } else {
      warning "Text is missing from tweet. ".Dumper($tweet);
    }
  }
  return @text_array;
}

# Reusing the twitter client could potentially cause issues but I haven't seen any thus far.
sub twitter_client {
  unless (defined $CLIENT) {
    $CLIENT = Net::Twitter->new(
      traits => ['API::RESTv1_1', 'OAuth'],
      consumer_key => $TWITTER_CONSUMER_KEY,
      consumer_secret => $TWITTER_CONSUMER_SECRET
    );

    my($access_token, $access_token_secret) = get_tokens();

    if ($access_token && $access_token_secret) {
        $CLIENT->access_token($access_token);
        $CLIENT->access_token_secret($access_token_secret);
    }

    if ($CLIENT->authorized) {
      return $CLIENT;
    } else {
      $CLIENT = undef; # reset this
      return undef;
    }
  } else {
    return $CLIENT;
  }
}

# In a real app this would probably want to get OAuth tokens for each logged in user, but in this case I'll just return my own tokens to keep it simple.
sub get_tokens {
  my $token = '2196328135-PQddLsjcNobHpHcs5Gt4M8q75AveRgN61xImxFX';
  my $secret = 'db91hOyX83ZKuTRd4S6jQUTOTl82IOQWOY9DAkfPvkK2q';
  return ($token, $secret);
}

true;
