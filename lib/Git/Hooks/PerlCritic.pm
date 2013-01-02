package Git::Hooks::PerlCritic;
use 5.010;
use strict;
use warnings;

# VERSION

use Carp;
use Git::Hooks;
use Perl::Critic;
use Perl::Critic::Violation;

sub changed {
	my $git = shift;

	my @changed
		= grep { /\.(p[lm]|t)$/xms }
		$git->command( qw/diff --cached --name-only --diff-filter=AM/ )
		;

	return \@changed;
}

sub check_violations {
	my $files = shift;

	my @violations;
	foreach my $file ( @$files ) {
		state $critic = Perl::Critic->new;

		@violations = $critic->critique( $file );
	}

	return \@violations;
}

PREPARE_COMMIT_MSG {
	my ( $git, $commit_msg_file ) = @_;

	my $changed    = changed( $git );
	my $violations = check_violations( $changed );

};

PRE_COMMIT {
	my $git = shift;

	my $changed    = changed( $git );
	my $violations = check_violations( $changed );

	if ( @$violations ) {
		print @$violations;
		# . operator causes the array ref to give count, otherwise it would
		# stringify
		croak 'please fix ' . @$violations . ' perl critic errors before committing';
	}
};

1;

# ABSTRACT: Git::Hooks::PerlCritic
