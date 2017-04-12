use Module::Build;
use 5.008001;
Module::Build->new
    (
    module_name => 'XML::ExtOn',
    license => 'perl',
    requires => {
        'perl' => 5.008001,
	},
    meta_merge => {
        resources => {
            repository => 'http://github.com/zag/p5-XML-ExtOn',
        },
    },
    prereq => {
	      'XML::SAX'=>'0',
	      'XML::SAX::Base' => 0,
	      'XML::SAX::Writer'=>0,
	      'XML::Parser::PerlSAX'=>0,
	      'XML::SAX::ParserFactory' => 0,
	      'Tie::UnionHash'=>'0',
	      'XML::NamespaceSupport' =>0,
	      'XML::Flow' =>'0.85',
	       },
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
