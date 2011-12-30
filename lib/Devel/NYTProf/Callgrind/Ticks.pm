package Devel::NYTProf::Callgrind::Ticks; # represents a mesh of Ticks read from a callgrind file

use strict;
use warnings;
our $VERSION = '0.01';

use Data::Dumper;

use Moose;




# file to be loaded
has 'file' => (
    is => 'rw',
    isa => 'Str',
);

# returns the list of blocks,
# or writes them
has 'list' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub{[]},
);


has 'blocks_by_id' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub{{}},
);




sub BUILD{
    my $self = shift;

    # file to be loaded?
    if ( $self->file() ){
        $self->loadFile( $self->file() );
    }

}

# loads the callgrind file into memory and starts linking
sub loadFile{
    my $self = shift;
    my $file = shift;
    
    if ( not -f $file ){ die "file $file does not exist" }; 

    open( my $fh, $file );

    my $area;
    my $block;
    my @list;
    while ( my $line = <$fh> ){
        $line =~ s/\n//; # remove return

        # starting an area
        if ( $line =~ m/events:\s(\w+)/i ){
            $area = lc($1);
            next;
        }

        # skip line if not type ticks
        if ( $area ne 'ticks' ){ next };

        # empty line is cleaning the block buffer
        if ( $line =~ m/^\s*$/ ){

            # save the found block infos
            if ( scalar( keys %$block ) != 0 ){ push @list,$block };

            $block={};
            next;
        }

        # is there a equals char? (=)
        if ( $line =~ m/(\w+)=(.+)/ ){
            my $key   = $1;
            my $value = $2;
            $block->{ $key } = $value;

            if ( $key eq 'calls' ){
                my ($count, $dstpos) = split(/ /, $value, 2);
                $block->{ 'count' }  = $count;
                $block->{ 'dstpos' } = $dstpos;
            }
        }

        ## read the ticks
        if ( $line =~ m/^(\d+) (\d+)$/ ){
            $block->{ 'srcpos' } = $1;
            $block->{ 'ticks' }  = $2;
        }

    } # while

    # no blank line on the end? save the block if needed
    if ( keys %$block ){ push @list,$block };

    #print Dumper( \@list );

    # save the callgrind list holding blocks
    $self->list( \@list );
    $self->_buildIdHash();

    close( $fh );
}


# build hash to for list_by_id to find
# nodes by a fingerprint/id
sub _buildIdHash{
    my $self = shift;
    my $list = $self->list();
    my $idhash = {};

    foreach my $block (@$list){
        my $id = $self->_createFingerprintOfBlock( $block );

        $idhash->{ $id } = $block;
    }
    
    #print Dumper( $idhash );
    $self->blocks_by_id( $idhash );
}

# Adds a block. For example you start with an
# empty object and wants to add blocks from
# a different object. It will replace an existing
# block if the definition existists already. So
# addBlock can also be used to update a block.
# If you update an existing block, it does break
# the reference to the given hashref, it makes a copy
# of the values.
sub addBlock{
    my $self = shift;
    my $block = shift;

    my $id = $self->_createFingerprintOfBlock( $block );
    my $found = $self->blocks_by_id()->{ $id };

    # if already in, replace it, otherwise add it
    if ( $found ){
        %{ $found } = %{ $block };
    }else{
        if ( scalar( keys %$block ) != 0 ){ 
            push @{ $self->list() }, $block;
            $self->blocks_by_id()->{ $id } = $block;
        }
    }

}


# Takes a callgrind block and creates a unique string
# to compare different files and find the same block.
sub _createFingerprintOfBlock{
    my $self = shift;
    my $block = shift;
    my $id;

    my @keys = qw( fl fn srcpos cfl cfn dstpos );

    my @id;
    foreach my $w (@keys){
        push @id, $block->{ $w } || '';
    }
    $id = join("#", @id);

    return $id;
}


# returns the equivalent block in that object to a given
# strange block (from a different object).
# Returns undef if not found.
sub getBlockEquivalent{
    my $self = shift;
    my $block = shift;
    my $found = undef;

    my $id = $self->_createFingerprintOfBlock( $block );

    if ( exists $self->blocks_by_id()->{ $id } ){
        $found = $self->blocks_by_id()->{ $id };
    }

    return $found;
}


# Is the same as list()
sub getBlocksAsArray{
    my $self = shift;

    return $self->list();
}


# Save the data to a callgrind file. The event type will
# be 'Ticks', nothing else.
sub saveFile{
    my $self = shift;
    my $file = shift;
    
    my $text = $self->getAsText();

    open( my $fh, ">$file" ) or die "Can not write file $file";

        print $fh $text;

    close( $fh );

}



sub getAsText{
    my $self = shift;
    my @lines;    

        push @lines, "events: Ticks";
        push @lines, "";

        my @pairs = qw( fl fn cfl cfn calls );

        foreach my $node ( @{ $self->list() } ){

            my @block = ();

            foreach my $p ( @pairs ){
                push @block,"$p=".$node->{$p} if exists $node->{$p};
            }

            push @lines, join( "\n", @block );
            push @lines, $node->{'srcpos'}.' '.$node->{'ticks'};
            push @lines, "";


        }
        
    return join( "\n", @lines );
}


1;
