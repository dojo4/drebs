# -*- encoding : utf-8 -*-
# built-ins
#

# DREBS libs
#
  module DREBS
    Version = '0.1.1' unless defined?(Version)

    def version
      DREBS::Version
    end

    def dependencies
      {
        'right_aws' => ['right_aws', '>= 3.1.0'],
        'logger'    => ['logger'   , '>= 1.2.8'],
        'main'      => ['main'     , '>= 5.2.0'],
        'systemu'   => ['systemu'  , '>= 2.4.2'],
        'json'      => ['json'     , '>= 1.5.1'],
        'pry'       => ['pry'      , '>= 0.9.12.6'],
      }
    end

    def libdir(*args, &block)
      @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
      args.empty? ? @libdir : File.join(@libdir, *args)
    ensure
      if block
        begin
          $LOAD_PATH.unshift(@libdir)
          block.call()
        ensure
          $LOAD_PATH.shift()
        end
      end
    end

    def load(*libs)
      libs = libs.join(' ').scan(/[^\s+]+/)
      DREBS.libdir{ libs.each{|lib| Kernel.load(lib) } }
    end

    extend(DREBS)
  end
  Drebs = DREBS

# gems
#
  begin
    require 'rubygems'
  rescue LoadError
    nil
  end

  if defined?(gem)
    DREBS.dependencies.each do |lib, dependency|
      gem(*dependency)
      require(lib)
    end
  end

  DREBS.load %w[
]
