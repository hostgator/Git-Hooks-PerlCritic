package Git::Hooks::PerlCritic;
use 5.010;
use strict;
use warnings;

# VERSION

use DDP;
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

	p $files;

	my @violations;
	foreach my $file ( @$files ) {
		state $critic = Perl::Critic->new;

		@violations = $critic->critique( $file );
	}

	p @violations;
	return \@violations;
}

PREPARE_COMMIT_MSG {
	my ( $git, $commit_msg_file ) = @_;

	my $changed    = changed( $git );
	my $violations = check_violations( $changed );
};

PRE_COMMIT {
	my $git = shift;

	carp 'Running';

	my $changed    = changed( $git );
	my $violations = check_violations( $changed );

	if ( @$violations ) {
		croak 'please fix the following violations before committing: '
			. @$violations;
	}
};

1;

# ABSTRACT: Git::Hooks::PerlCritic
