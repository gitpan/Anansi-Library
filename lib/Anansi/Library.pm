package Anansi::Library;


=head1 NAME

Anansi::Library - A base module definition for object functionality extension.

=head1 SYNOPSIS

 # Note: As 'base' needs a module file, this package must be declared in 'LibraryExample.pm'.
 package LibraryExample;

 use base qw(Anansi::Library);

 sub libraryExample {
     my ($self, %parameters) = @_;
 }

 1;

 # Note: This package should be declared in 'ClassExample.pm'.
 package ClassExample;

 use base qw(Anansi::Class LibraryExample);

 sub classExample {
     my ($self, %parameters) = @_;
     $self->libraryExample();
     $self->LibraryExample::libraryExample();
 }

 1;

=head1 DESCRIPTION

This is a base module definition that manages the functionality  extension of
module object instances.

=cut


our $VERSION = '0.02';


my $LIBRARY = {};


=head1 METHODS

=cut


=head2 abstractClosure

 my $CLOSURE = Anansi::Library->abstractClosure(
  'Some::Namespace',
  'someKey' => 'some data',
  'anotherKey' => 'Subroutine::Namespace',
  'yetAnotherKey' => Namespace::someSubroutine,
 );
 $CLOSURE->anotherKey();
 $CLOSURE->yetAnotherKey();

 sub Subroutine::Namespace {
     my ($self, $closure, %parameters) = @_;
     my $abc = %{$closure}->{abc} || 'something';
     %{$closure}->{def} = 'anything';
 }

Create a blessed object with the namespace as defined in the first parameter and
initialise the object with the subsequent KEY/VALUE pairs, storing them within a
HASH that is only accessible from within the scope of the object.  A VALUE
containing a subroutine namespace STRING or a CODEREF will be interpreted as an
object method and will be passed the locally accessible HASH when executed.

=cut


sub abstractClosure {
    my (undef, $abstract, %parameters) = @_;
    my $ABSTRACT = {
        NAMESPACE => $abstract,
    };
    my $CLOSURE = {
    };
    foreach my $key (keys(%parameters)) {
        next if('NAMESPACE' eq $key);
        if(ref($parameters{$key}) =~ /^CODE$/i) {
            *{$abstract.'::'.$key} = sub {
                my ($self, @PARAMETERS) = @_;
                return &{$parameters{$key}}($self, $CLOSURE, (@PARAMETERS));
            };
        } elsif(ref($parameters{$key}) !~ /^$/i) {
            $CLOSURE->{$key} = $parameters{$key};
        } elsif($parameters{$key} =~ /^[a-zA-Z]+[a-zA-Z0-9_]*(::[a-zA-Z]+[a-zA-Z0-9_]*)+$/) {
            if(exists(&{$parameters{$key}})) {
                *{$abstract.'::'.$key} = sub {
                    my ($self, @PARAMETERS) = @_;
                    return &{\&{$parameters{$key}}}($self, $CLOSURE, (@PARAMETERS));
                };
            } else {
                $CLOSURE->{$key} = $parameters{$key}
            }
        } else {
            $CLOSURE->{$key} = $parameters{$key};
        }
    }
    return bless($ABSTRACT, $abstract);
}


=head2 abstractObject

 my $OBJECT = Anansi::Library->abstractObject(
  'Some::Namespace',
  'someKey' => 'some data',
  'anotherKey' => 'Subroutine::Namespace',
  'yetAnotherKey' => Namespace::someSubroutine,
 );
 $OBJECT->anotherKey();
 $OBJECT->yetAnotherKey();

 sub Subroutine::Namespace {
     my ($self, %parameters) = @_;
     my $abc = $self->{abc} || 'something';
     $self->{def} = 'anything';
 }

Create a blessed object with the namespace as defined in the first parameter and
initialise the object with the subsequent KEY/VALUE pairs.  A VALUE containing a
subroutine namespace STRING or a CODEREF will be defined as an object method.

=cut


sub abstractObject {
    my (undef, $abstract, %parameters) = @_;
    my $ABSTRACT = {
        NAMESPACE => $abstract,
    };
    foreach my $key (keys(%parameters)) {
        next if('NAMESPACE' eq $key);
        if(ref($parameters{$key}) =~ /^CODE$/i) {
            *{$abstract.'::'.$key} = $parameters{$key};
        } elsif(ref($parameters{$key}) !~ /^$/i) {
            $ABSTRACT->{$key} = $parameters{$key};
        } elsif($parameters{$key} =~ /^[a-zA-Z]+[a-zA-Z0-9_]*(::[a-zA-Z]+[a-zA-Z0-9_]*)+$/) {
            if(exists(&{$parameters{$key}})) {
                *{$abstract.'::'.$key} = *{$parameters{$key}};
            } else {
                $ABSTRACT->{$key} = $parameters{$key}
            }
        } else {
            $ABSTRACT->{$key} = $parameters{$key};
        }
    }
    return bless($ABSTRACT, $abstract);
}


=head2 hasAncestor

 my $MODULE_ARRAY = $OBJECT->hasAncestor();
 if(defined($MODULE_ARRAY));

 if(1 == $OBJECT->hasAncestor('Some::Module', 'Another::Module', 'Etc'));

Either returns an ARRAY of all the loaded modules that the OBJECT inherits from
or whether the OBJECT inherits from all of the specified loaded modules.

=cut


sub hasAncestor {
    return if(0 == scalar(@_));
    my $self = shift(@_);
    my %modules;
    while(my ($name, $value) = each(%INC)) {
        next if($name !~ /\.pm$/);
        $name =~ s/\.pm//;
        $name =~ s/\//::/g if($name =~ /\//);
        next if(!$self->isa($name));
        next if($self eq $name);
        $modules{$name} = 1;
    }
    if(0 == scalar(@_)) {
        return [( keys(%modules) )] if(0 < scalar(keys(%modules)));
        return;
    }
    while(0 < scalar(@_)) {
        my $name = shift(@_);
        return 0 if(!defined($modules{$name}));
    }
    return 1;
}


=head2 hasDescendant

 my $MODULE_ARRAY = $OBJECT->hasDescendant();
 if(defined($MODULE_ARRAY));

 if(1 == $OBJECT->hasDescendant('Some::Module', 'Another::Module', 'Etc'));

Either returns an ARRAY of all the loaded modules that the OBJECT is inherited
from or whether the OBJECT is inherited from all of the specified loaded
modules.

=cut


sub hasDescendant {
    return if(0 == scalar(@_));
    my $self = shift(@_);
    my %modules;
    while(my ($name, $value) = each(%INC)) {
        next if($name !~ /\.pm$/);
        $name =~ s/\.pm//;
        $name =~ s/\//::/g if($name =~ /\//);
        next if(!$name->isa($self));
        next if($self eq $name);
        $modules{$name} = 1;
    }
    if(0 == scalar(@_)) {
        return [( keys(%modules) )] if(0 < scalar(keys(%modules)));
        return;
    }
    while(0 < scalar(@_)) {
        my $name = shift(@_);
        return 0 if(!defined($modules{$name}));
    }
    return 1;
}


=head2 hasLoaded

 my $MODULE_ARRAY = $OBJECT->hasLoaded();
 if(defined($MODULE_ARRAY));

 my $MODULE_ARRAY = Anansi::Library->hasLoaded();
 if(defined($MODULE_ARRAY));

 if(1 == $OBJECT->hasLoaded('Some::Module', 'Another::Module', 'Etc'));

 if(1 == Anansi::Library->hasLoaded('Some::Module', 'Another::Module', 'Etc'));

Either returns an ARRAY of all the loaded modules or whether all of the
specified modules have been loaded.

=cut


sub hasLoaded {
    return if(0 == scalar(@_));
    my $self = shift(@_);
    my %modules;
    while(my ($name, $value) = each(%INC)) {
        next if($name !~ /\.pm$/);
        $name =~ s/\.pm//;
        $name =~ s/\//::/g if($name =~ /\//);
        $modules{$name} = 1;
    }
    if(0 == scalar(@_)) {
        return [( keys(%modules) )] if(0 < scalar(keys(%modules)));
        return;
    }
    while(0 < scalar(@_)) {
        my $name = shift(@_);
        return 0 if(!defined($modules{$name}));
    }
    return 1;
}


=head2 hasSubroutine

 my $SUBROUTINE_ARRAY = $OBJECT->hasSubroutine();
 if(defined($SUBROUTINE_ARRAY));

 if(1 == $OBJECT->hasSubroutine('someSubroutine', 'anotherSubroutine', 'etc'));

Either returns an ARRAY of all the subroutines in the loaded module or whether
the loaded module has all of the specified subroutines.

=cut


sub hasSubroutine {
    return if(0 == scalar(@_));
    my $self = shift(@_);
    no strict 'refs';
    my %subroutines = map { $_ => 1 } grep { exists &{"$self\::$_"} } keys %{"$self\::"};
    if(0 == scalar(@_)) {
        return [( keys(%subroutines) )] if(0 < scalar(keys(%subroutines)));
        return;
    }
    while(0 < scalar(@_)) {
        my $name = shift(@_);
        return 0 if(!defined($subroutines{$name}));
    }
    return 1;
}


INIT {
};

=head1 AUTHOR

Kevin Treleaven <kevin AT treleaven DOT net>

=cut


1;
