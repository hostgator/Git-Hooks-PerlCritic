package Git::Hooks::PerlCritic;
use 5.010;
use strict;
use warnings;

# VERSION

use Carp;
use Module::Load 'load';
use Git::Hooks;

sub _changed {
	my $git = shift;

	my @changed
		= grep { /\.(p[lm]|t)$/xms }
		$git->command( qw/diff --cached --name-only --diff-filter=AM/ )
		;

	return \@changed;
}

sub _set_critic {
	load 'Perl::Critic';
	load 'Perl::Critic::Violation';
	load 'Perl::Critic::Utils';

	my $pc = Perl::Critic->new;
	my $verbosity = $pc->config->verbose;

	# set the format to be a comment
	my $fmt = Perl::Critic::Utils::verbosity_to_format( $verbosity );
	Perl::Critic::Violation::set_format( "# $fmt" );

	return $pc;
}

sub _check_violations {
	my $files = shift;

	my @violations;
	foreach my $file ( @$files ) {
		state $critic = _set_critic;

		@violations = $critic->critique( $file );
	}

	return \@violations;
}

PREPARE_COMMIT_MSG {
	my ( $git, $commit_msg_file ) = @_;

	my $changed    = _changed( $git );
	my $violations = _check_violations( $changed );

	if ( @$violations ) {
		my $pcf = 'Path::Class::File'; load $pcf;
		my $file     = $pcf->new( $commit_msg_file );
		my $contents = $file->slurp;

		# a space is being prepended, suspect internal join, remove it
		( $contents .= "@$violations" ) =~ s/^\ #//xmsg;

		$file->spew( $contents );
	}
};

PRE_COMMIT {
	my $git = shift;

	my $changed    = _changed( $git );
	my $violations = _check_violations( $changed );

	if ( @$violations ) {
		print @$violations;
		# . operator causes the array ref to give count, otherwise it would
		# stringify
		croak '# please fix ' . @$violations . ' perl critic errors before committing';
	}
};

1;

# ABSTRACT: Perl Critic hooks for git

=head1 SEE ALSO

=over

=item L<Git::Hooks>

=back
