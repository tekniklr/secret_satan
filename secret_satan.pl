#!/usr/bin/perl -w

# secret_satan.pl
#	This script will parse the provided array of persons to generate a
#	one to one relationship between them, suitable for gift giving.

use strict;
use Text::Wrap;

######################################################################
## CONFIGURATION
######################################################################

# debug level - 0 for normal operation (participants will recieve email
# regarding their victims, said information will be hidden from 
# instigator.)
my $debug = 1;

# the name for whatever shindig (e.g., Fake Xmas) this is for.  free-text
my $xmas_name = 'this year\'s Fake Xmas';
# the date for whatever shindig (e.g., Fake Xmas) this is for.  free-text
my $xmas_date = 'Saturday, Dec. 8, 2007';
# a note about min/max time/effort/cost for presents.  free-text
my $gift_range = 'no more than $40 and no less than $20 US dollars';

# paricipant array-of-hashes
#	each participant can have the following data:
#		'nickname' (required, also must be unique)
#		'name' (required)
#		'email' (required)
#		'unfriends' (optional- an array of people [nickname] this person
#			does not know well enough to be expected to terrorize, or, 
#			alternately, people they know are already buying gifts for)
my @victims = (
	{
		'nickname' => 'thing1',
		'name' => 'Jane Doe',
		'email' => 'thing1@example.com',
		'unfriends' => undef
	},
	{
		'nickname' => 'thing2',
		'name' => 'John Doe',
		'email' => 'thing2@example.com',
		'unfriends' => undef
	},
 	{
		'nickname' => 'antithing1',
 		'name' => 'Hates Thing',
 		'email' => 'antithing1@example.com',
 		'unfriends' => ['thing1']
 	}
# 	{
#		'nickname' => '',
# 		'name' => '',
# 		'email' => '',
# 		'unfriends' => undef
# 	},
);

# if we are debugging, don't mail the satans, instead send all 
# notifications to this address
my $debug_mail = 'debug@example.com';
# who mail will appear to come from
my $mail_sender = 'from@example.com';
# the program which will be used to send mail
my $mail_program = '/path/to/sendmail';

# the maximum number of tries before the program gives the search up for a
# loss - to detect impossible combinations (possible!) and prevent infinite
# loops
my $max_tries = 10;

######################################################################
## SUBROUTINES
######################################################################

# 'randomize' array
sub shuffle {
	my $array = shift;
	my $i = scalar(@$array);
	my $j;
	foreach my $item (@$array ) {
		--$i;
		$j = int rand ($i+1);
		next if $i == $j;
		@$array [$i,$j] = @$array[$j,$i];
	}
	return @$array;
}

# unset any satan/victim associations
sub refresh {
	my $array = shift;
	foreach (@$array) {
		$_->{'satan'} = undef;
	}
	return @$array;
}

######################################################################
## STUFF
######################################################################

# keep track of how many times we've tried to find a match this run...
my $tries = 0;

START:
@victims = refresh(\@victims);

# make sure we only try this a reasonable number of times
$tries++;
if ($tries > $max_tries) {
	die "Your satans aren't friendly enough, apparently.\nI tried to pair them up $max_tries, and then (reasonably) gave up.\n";
}

# announce out how many victims there will be...
my $remaining_victims = @victims;
print "Finding secret victims for ".$remaining_victims." satans...\n";

# randomize array, so that satan order is less predictable
@victims = shuffle(\@victims);

# sort victims so that ones with more restrictions will get victims
# first
my %sorted_victims = ();
my $random_place = 0;
foreach (@victims) {
	($debug > 2) and print "\tSorting ".$_->{'nickname'}."...\n";
	my @unfriends = ();
	if ($_->{'unfriends'}) {
		@unfriends = @{$_->{'unfriends'}};
	}
	my $num_unfriends = @unfriends;
	my $victim_key = $num_unfriends.'_'.$random_place.'_'.$_->{'nickname'};
	$sorted_victims{$victim_key} = $_;
	$random_place++;
}

# randomize array, so that victim order is less predictable
@victims = shuffle(\@victims);

# starting with most restrictive people, match satans to victims
foreach my $satan (reverse sort(keys %sorted_victims)) {
	my $satan_nick = $sorted_victims{$satan}{'nickname'};
	my @unfriends = ();
	if ($sorted_victims{$satan}{'unfriends'}) {
		@unfriends = @{$sorted_victims{$satan}{'unfriends'}};
	}
	my $num_unfriends = @unfriends;

	print "\tFinding target for ".$satan_nick." (".$num_unfriends." unfriends)...\n";

	# make sure of certain things...
	foreach (@victims) {
		my $victim_nick = $_->{'nickname'};
		($debug > 2) and print "\t\tChecking against $victim_nick\n";

		# first, that a satan doesn't get matched to themself
		if ($satan_nick eq $victim_nick) {
			($debug > 2) and print "\t\t\t$victim_nick is the same entity!\n";
			next;
		}

		# second, that a satan doesn't get matched to someone they
		# are unfriends with
		if ($num_unfriends > 0) {
			my @match_unfriends = grep(/${victim_nick}/i, @unfriends);
			if (@match_unfriends > 0) {
				($debug > 2) and print "\t\t\t$victim_nick is an unfriend!\n";
				next;
			}
		}

		# third, that a satan doesn't get matched to a victim who has
		# already been claimed
		if ($_->{'satan'}) {
			($debug > 2) and print "\t\t\t$victim_nick has already been claimed by ".$_->{'satan'}."!\n";
			next;
		}

		# if we've gotten this far, we have a victim!
		($debug > 1) and print "\t\t\t$victim_nick is our selected victim!\n";
		$_->{'satan'} = $satan_nick;
		$sorted_victims{$satan}{'victim'} = $_->{'name'};
		last;

	}
}

# now that all matching has been attempted, try to ensure everyone has
# successfully been matched
foreach (@victims) {
	my $victim_nick = $_->{'nickname'};
	($debug > 1) and print "\tVerifying that $victim_nick has been targeted...\n";
	if (!$_->{'satan'}) {
		print "Association failed.  Retrying...\n";
		goto START;
	}
}

# if we've gotten this far, we have met with some success.
print "All satans have been assigned victims, and in only $tries attempt(s)!\n\n";

# now that all the work is done, we go through the list one more time and 
# send everyone their secret notifications!
# if we are in debug mode, instead send all mails to the $debug_mail
# starting with most restrictive people, match satans to victims
print "Sending notifications...\n";
foreach my $satan (keys %sorted_victims) {
	my $satan_name = $sorted_victims{$satan}{'name'};
	my $satan_email = $sorted_victims{$satan}{'email'};
	my $satan_victim = $sorted_victims{$satan}{'victim'};
	($debug > 1) and print "\tLetting $satan_name know that $satan_victim is their victim...\n";

	my $mailto = $satan_email;
	$debug and $mailto = $debug_mail;
	my $mail_subject = "You are ${satan_victim}'s designated gift giver!";
	my $mail_text = <<END_TEXT;
Greetings, ${satan_name}.  This is the automated present notification bot for ${xmas_name} (${xmas_date}).
	
Consider this message your notification that it is your responsibility to ensure that ${satan_victim} feels loved* this year.  Don't be a cad.

It's a secret to everybody, except you!



(*) Although there are many ways to feel loved, for the purpose of this event it is assumed that love will be shown by offerings of a material sort, chosen in a thoughtful manner.  Such items may be crafted or purchased, but effort and cost should be kept within reasonable** limits.

(**) Whatever those are.  Lets say ${gift_range}, that sounds about right.

END_TEXT
	$Text::Wrap::columns = 72;
	$mail_text = wrap('', '', $mail_text);
	($debug > 3) and print $mail_text;

	# send mail
	print "\tSending mail to $mailto...\n";

	open(SENDMAIL, "|${mail_program} -f ${mail_sender} -t") or die "Cannot open ${mail_program}: $!";
	print SENDMAIL "Subject: ${mail_subject}\n";
	print SENDMAIL "To: ${mailto}\n";
	print SENDMAIL "Content-type: text/plain\n\n";
	print SENDMAIL $mail_text;
	close(SENDMAIL);
}
