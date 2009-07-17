# ===========================================================================
# A Movable Type plugin to remove entry pages from disk on entry deletion.
# Copyright 2006 Everitz Consulting <everitz.com>.
#
# This program is free software:  You may redistribute it and/or modify it
# it under the terms of the Artistic License version 2 as published by the
# Open Source Initiative.
#
# This program is distributed in the hope that it will be useful but does
# NOT INCLUDE ANY WARRANTY; Without even the implied warranty of FITNESS
# FOR A PARTICULAR PURPOSE.
#
# You should have received a copy of the Artistic License with this program.
# If not, see <http://www.opensource.org/licenses/artistic-license-2.0.php>.
# ===========================================================================
package MT::Plugin::DeletedEntry;

use base qw(MT::Plugin);
use strict;

use MT;

my $DeletedEntry;
my $about = {
  name => 'MT-DeletedEntry',
  description => 'Remove entry pages from disk on entry deletion.',
  author_name => 'Everitz Consulting',
  author_link => 'http://everitz.com/',
  version => '0.1.3'
};
$DeletedEntry = MT::Plugin::DeletedEntry->new($about);
MT->add_plugin($DeletedEntry);

require MT::Category;
MT::Category->add_callback('pre_remove', 10, $about, \&remove_category);

require MT::Entry;
MT::Entry->add_callback('pre_remove', 10, $about, \&remove_entry);

require MT::Request;

sub remove_category {
  my $app = MT->instance;
  my ($err, $obj) = @_;
  my $r = MT::Request->instance;
  my $categories = $r->stash('MT_DeletedEntry_Categories') || {};
  $categories->{$obj->category_id} = 1;
  $r->stash('MT_DeletedEntry_Categories', $categories);
}

sub remove_entry {
  my $app = MT->instance;
  my ($err, $obj) = @_;

  use MT::Request;
  my $r = MT::Request->instance;
  my $categories = $r->stash('MT_DeletedEntry_Categories') || {};
  my @categories = (keys %$categories);

  # Get the entry URL
  use MT::Entry;
  my $entry = MT::Entry->load($obj->id);
  my $entry_url = $entry->permalink;
  $app->log('Entry URL: '.$entry_url);

  # Get blog URL and filesystem path
  use MT::Blog;
  my $blog = MT::Blog->load($obj->blog_id);
  my $host_path = $blog->site_path();
  my $host_url = $blog->site_url();
  $app->log('Site Path: '.$host_path);
  $app->log('Site URL: '.$host_url);

  # Extract filename
  my $entry_file = $entry_url;
  $entry_file =~ s/([^/]*\.php)$//;
  $app->log('Entry File: '.$entry_file);

  require MT::Util;
  if (@categories) {
    foreach (@categories) {
      my $full_path = $host_path.'/'.MT::Util::dirify($_).'/'.$entry_file;
      $app->log('Full Entry Path: '.$full_path);
      if (-f $full_path) {
        my $res = unlink ($entry_path);
        my $message = 'Removed';
        $message = 'Error removing' unless ($res);
        $app->log($message.' '.$entry_path);
      } else {
        $app->log('Not found.');
      }
    }
  } else {
    my $full_path = $host_path.'/'.$entry_file;
    $app->log('Full Entry Path: '.$full_path);
    if (-f $full_path) {
      my $res = unlink ($entry_path);
      my $message = 'Removed';
      $message = 'Error removing' unless ($res);
      $app->log($message.' '.$entry_path);
    } else {
      $app->log('Not found.');
    }
  }
}

1;
