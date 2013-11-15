package crowdtilt_dev_test;
use Dancer ':syntax';
use strict;
use warnings;
use Cwd;
use Sys::Hostname;
use Set::Intersection;
use Twitter::Client;
use Twitter::Markup;
use Data::Dumper;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/tweets/:screen_name' => sub {
  my @tweets = Twitter::Client::get_tweets(param('screen_name'));
  @tweets = Twitter::Markup::markup_tweets(@tweets);
  template 'twitter/tweets' => { tweets => \@tweets };
};

get '/intersection/:screen_name_1/:screen_name_2' => sub {
  # Many API call way would be get friends of user1, call friendship_exists(friend[i], user2) but that is awful so we'll not do that. Instead we should just get user1's friends, user2's friends, and do the intersection locally.
  my @friend_ids_1 = Twitter::Client::get_friends(param('screen_name_1'));
  my @friend_ids_2 = Twitter::Client::get_friends(param('screen_name_2'));
  my @intersection_ids = Set::Intersection::get_intersection(\@friend_ids_1, \@friend_ids_2);
  my @users = Twitter::Client::lookup_users(@intersection_ids);
  template 'twitter/intersection' => {
    screen_name_1 => param('screen_name_1'),
    screen_name_2 => param('screen_name_2'),
    users => \@users
  };

};

true;
