#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Pod::Usage;
use Gtk2::Ex::FormFactory;


my $config_object = {
	'name' => 'rich',
	'age' => 34
};

{ package Thing;
	sub get_name
	{
		my $self = shift;
		$$self{name};
	}
	sub get_age
	{
		my $self = shift;
		$$self{age};
	}
	sub get_selected_page { 1 }
}

bless $config_object, 'Thing';

my $context = Gtk2::Ex::FormFactory::Context->new;
$context->add_object (
	name   => "config",
	object => $config_object
);


my $ff = Gtk2::Ex::FormFactory->new (
    context => $context,
    content => [
      Gtk2::Ex::FormFactory::Window->new(
        title   => "Preferences",
        content => [
          Gtk2::Ex::FormFactory::Notebook->new (
            attr    => "config.selected_page",
            content => [
              Gtk2::Ex::FormFactory::VBox->new (
                title   => "Filesystem",
                content => [
                  Gtk2::Ex::FormFactory::Form->new (
                    content => [
                      Gtk2::Ex::FormFactory::Entry->new (
                        attr   => "config.name",
                        label  => "Data Directory",
                        tip    => "This directory takes all your files.",
                        rules  => "writable-directory",
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Gtk2::Ex::FormFactory::DialogButtons->new
        ],
      ),
    ],
  );
 
$ff->open;    # actually build the GUI and open the window
$ff->update;  # fill in the values from $config_object


# {{{
# See http://perldoc.perl.org/Getopt/Long.html
# can set default options like this:
my %opts = ( 
		'verbose' => 0,
		'help'    => 0
		);

GetOptions (\%opts, 'include=s@', 'help' );
# typed things
# --------------------------------------------
# string			: filename=s 
# repeated string	: filenames=s@
# bool				: help!  or just 	help
# 					  Nb. --help will set 1, --no-help will set 0
# integer			: count=i
# perl integer		: qty=o
# 					  e.g. --qty=0x20 for 32
# real number		: price=f
#
# typed things: optional values
# --------------------------------------------
# string			: filename:s
# ...

# validate options and throw help back if the dear user has clearly misunderstood
# $opts{'help'}=1 if ( ... );

pod2usage(1) if ($opts{'help'});
# }}}



# { package Animal;
# 	sub speak 
# 	{
# 		my $class = shift;
# 		print "A $class goes " , $class->sound, "!\n";
# 	}
# 	sub named
# 	{
# 		my $class_or_instance = shift;
# 		print ref $class_or_instance, "\n";
# 		$$class_or_instance;
# 	}
# }
# 
# { package Horse;
# 	use vars qw|@ISA|;
# 	@ISA = qw(Animal);
# 	sub sound { "neigh" }
# }
# Horse->speak();
# my $name = "Mr. Ed";
# 
# my $talking = \$name;
# bless $talking, 'Horse';
# 
# print "MY horse is called ", $talking->named , " and he goes ", $talking->sound, "\n";






__END__

=head1 NAME

this program does this...B<This program>

=head1 SYNOPSIS

program [options] files etc.

Options:
-help brief help message

=head1 OPTIONS

=over 8

=item B<-xxxoptxxx>

help about xxxoptxxx option

=item B<-yyyoptyyy>

help about yyyoptyyy option

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut

