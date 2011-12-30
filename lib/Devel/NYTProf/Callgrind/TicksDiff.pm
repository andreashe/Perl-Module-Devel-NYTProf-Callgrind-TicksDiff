package Devel::NYTProf::Callgrind::TicksDiff; # Calculates a delta between 2 callgrind files

use strict;
use warnings;
use Devel::NYTProf::Callgrind::Ticks;
our $VERSION = '0.01';


use Moose;

# callgrind files to be compared
has 'files' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {[]},
);


has 'file_out' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {[]},
);

# Objects of ticks Devel::NYTProf::Callgrind::TicksD
has 'ticks_objects' => (
    is => 'rw',
    isa => 'ArrayRef',
    builder => '_loadFiles',
);


has 'ticks_object_out' => (
    is => 'rw',
    default => undef,
);

# enable normalization
has 'normalize' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


# if negative ticks are allowed or be truncated to 0
has 'allow_negative' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


sub _loadFiles{
    my $self = shift;
    my @files = @{ $self->files() };
    my @objs;

    foreach my $file (@files){
        
        my $ticks = Devel::NYTProf::Callgrind::Ticks->new( file => $file );
        push @objs, $ticks;
    }

    
  $self->ticks_objects( \@objs );
}



# starts the compare process. So far it compares only
# two files. Returning infos in a hash.
sub compare{
    my $self = shift;
    my $objs = $self->ticks_objects(); 
    my $result = {};

    my $obj_a = $objs->[0];
    my $obj_b = $objs->[1];

    my $notfound = 0;
    my $delta_total = 0;
    my $delta_less = 0;
    my $delta_more = 0;
    my $max_less = 0;


    ## remember deltas for new blocks
    my $deltaInfo = [];

    foreach my $block_a ( @{ $obj_a->list() } ){

       my $block_b = $obj_b->getBlockEquivalent( $block_a );

       if ( $block_b ){
            my $delta = $self->diffBlocks( $block_a, $block_b );
            $delta_total += $delta;
            
            if ( $delta > 0 ){
                $delta_more += $delta;
            }else{
                $delta_less += $delta;

                # remember the biggest negative value.
                # to enable shifting when normalize is on
                if ( $delta < $max_less ){
                    $max_less = $delta;
                }
            }

            push @$deltaInfo, {
                            delta   => $delta,
                            block_a => $block_a,
                            block_b => $block_b,
                              };


            #print $delta."\n";

       }else{
            $notfound++;
       }

    }



    ## build new delta blocks.
    ## iterate over the stored delta info list with
    ## refs to the original blocks
    
    ## new ticks object to store the delta info in
    my $nobj =  Devel::NYTProf::Callgrind::Ticks->new();
    my $norm = $self->normalize();
    my $allow_negative = $self->allow_negative(); 
    foreach my $deltaInfo ( @{ $deltaInfo } ){

            my $block_a = $deltaInfo->{'block_a'};

            ## now build a new block
            my $nblock = {};
            %{ $nblock } = %{ $block_a }; # copy the existing block

            if ( scalar( keys %$nblock ) == 0 ){ next }; # skip empty

            my $nticks = $deltaInfo->{'delta'}; # using the delta as ticks
            
            # normalization?
            # It will shift up all values by the maximum nagative delta
            # to have the lowest value as 0.
            if ( $norm ){
                $nticks = $nticks - $max_less; # it is a negative value
            }

            ## do not allow negative deltas.
            ## to avoid wrong info, you may use normalize
            if ( ($nticks < 0) && (!$allow_negative)){
                $nticks = 0;
            }

            $nblock->{'ticks'} = $nticks;
            
            # store to the new ticks object
            $nobj->addBlock( $nblock );        
    }
    
    ## save to official location
    $self->ticks_object_out( $nobj );


    $result = {
                not_found   => $notfound,
                delta_more  => $delta_more,
                delta_less  => $delta_less,
                delta_total => $delta_total,
                max_less    => $max_less,
              };




    return $result;
}


# Compares two single blocks (HasRefs) provided
# by the Ticks class of this package. It returns
# the tick difference between B and A. Means
# B-Ticks - A-Ticks.
sub diffBlocks{
    my $self = shift;
    my $blocka = shift or die "block as hashref required";
    my $blockb = shift or die "block as hashref required";
    
    my $ta = $blocka->{'ticks'};
    my $tb = $blockb->{'ticks'};

    return $tb - $ta;
}


# just a wrapper around ticks_object_out
sub getDeltaTicksObject{
    my $self = shift;

    return $self->ticks_object_out();
}


sub saveDiffFile{
    my $self = shift;
    my $file = shift or die "need filename";

    my $obj = $self->ticks_object_out();
    $obj->saveFile( $file );

    if ( ! -f $file ){ die "Did not create file $file" };

}


sub getDiffText{
    my $self = shift;

    my $obj = $self->ticks_object_out();
    return $obj->getAsText();
}



1;
