use MooseX::Declare;
use v5.10;

use Getopt::Long::Descriptive; 

class Devel::NYTProf::Callgrind::Command::diff extends(MooseX::App::Cmd::Command,Devel::NYTProf::Callgrind::Command) {
  
    has 'normalize' => (
        is  =>  'rw',
        isa =>  'Bool',
        documentation =>  'Increase all values with the maximum nagative value.',
    );

    has 'out' => (
        is  =>  'rw',
        isa =>  'Str',
        documentation =>  'Filename where it should write the diff to. Default is STDOUT.',
    );

    sub abstract {
        "Calculates the difference between 2 callgrind files.";
    }


    method execute (Ref $opt, ArrayRef $args) {

        if ( scalar( @$args ) < 2 ){
          $self->error("Can not compare with less than 2 files.");
        }

        my @files = @$args;
        $self->_checkIfFilesExist( \@files );
          

        use Devel::NYTProf::Callgrind::TicksDiff;
        my $tickdiff = Devel::NYTProf::Callgrind::TicksDiff->new( files => \@files );
            
        my $info = $tickdiff->compare();

        if ( $self->out() ){
            $tickdiff->saveDiffFile( $self->out() );
        }else{
            print $tickdiff->getDiffText();
        }

    }



    method _checkIfFilesExist (ArrayRef $files){
        
        foreach my $file ( @$files ){
            if ( ! -e $file ){
                $self->error( "At least file \'$file\' does not exist" );
            }
        }

    }



    method error (Str $msg){
        say $msg;
        exit 0;
    }


}




1;
