#!/usr/bin/env ruby
require 'rubygems'
require 'csv'
require 'logger'
require 'sequel'
require 'yaml'
require 'getoptlong'

# 
# Set up environment to use branches for correct GenBank files
ENV['GLOBAL_SYNTHVEC_DATADIR'] = "/software/team87/brave_new_world/data/mutant_sequences_draft"
ENV['PERL5LIB']                = "/nfs/users/nfs_t/team87/TargetedTrap/lib:/nfs/users/nfs_t/team87/htgtdb/lib:#{ENV['PERL5LIB']}"

@database    = ENV["HTGT_ENV"] == 'Devel' ? 'development' : 'production'
@debug       = false
@config_file = '/software/team87/brave_new_world/capistrano_managed_apps/production/idcc_targ_rep/shared/database.yml'

opts = GetoptLong.new(
    [ '--pipeline',    '-p', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--allele_ids',  '-a', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--config_file', '-c', GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--debug',       '-d', GetoptLong::NO_ARGUMENT       ]
)

opts.each do |opt, arg|
  case opt
  when '--pipeline'
    @pipeline    = arg
  when '--allele_ids'
    @allele_ids  = arg
  when '--config_file'
    @config_file = arg
  when '--debug'
    @debug       = true
  end
end

log      = Logger.new($stderr)
config   = YAML.load_file( @config_file )
db_conn  = Sequel.connect( config[@database] )

if @allele_ids.nil? and @pipeline.nil?
  puts "Require either allele_ids or pipeline"
  exit
elsif @allele_ids.nil? and not @pipeline.nil?
  log.info( "process pipeline (#{@pipeline}) ..." )
  pipeline = db_conn[:pipelines].filter(:name => @pipeline).first()
  @alleles = db_conn[:alleles].select(
    :id,
    :backbone,
    :cassette,
    :project_design_id,
    :loxp_start,
    :loxp_end
  ).filter( :pipeline_id => pipeline[:id] )
elsif not @allele_ids.nil? and @pipeline.nil?
  log.info( "process allele_ids (#{@allele_ids}) ..." )
  allele_ids = CSV.open(@allele_ids, "r").map do |row|
    row.first if not row.empty?
  end
  @alleles = db_conn[:alleles].select(
    :id,
    :backbone,
    :cassette,
    :project_design_id,
    :loxp_start,
    :loxp_end
  ).filter( :id => allele_ids )
  log.info( "#{@alleles.count} allele(s) to process" )
else
  puts "Can't have both allele_ids (#{@allele_ids}) and pipeline (#{@pipeline})"
  exit
end

genbank_files = db_conn[:genbank_files].join( @alleles, :id => :allele_id ).select(
    :id.qualify(:genbank_files),
    :backbone,
    :cassette,
    :project_design_id,
    :allele_id,
    :loxp_start,
    :loxp_end
)

log.info("we have #{ genbank_files.count } genbank file(s) to process")

command = "perl -mHTGT::Utils::GenerateGenBankString=:all -e 'print generate_genbank_string(@ARGV)'"

genbank_files.each do |genbank_file|
  data = {}

  if genbank_file[:loxp_start].nil? and genbank_file[:loxp_end].nil?
    data[:targeted_trap] = 1
  end

  # retrieve the escell_clone
  begin
    command_string = [
      command,
      'cassette',      genbank_file[:cassette],
      'design_id',     genbank_file[:project_design_id]
    ].join(" ")
    unless data[:targeted_trap].nil?
      command_string = [ command_string, 'targeted_trap', data[:targeted_trap] ].join(" ")
    end
    data[:escell_clone] = `#{ command_string }`
  rescue
    log.info( "Error generating the escell_clone:\n#{$!}" )
  end

  # retrieve the targeting_vector
  begin
    data[:targeting_vector] = `#{ [
      command,
      'cassette',      genbank_file[:cassette],
      'design_id',     genbank_file[:project_design_id],
      'backbone',      genbank_file[:backbone],
    ].join(" ") }`
  rescue
    log.info( "Error generating the targeting_vector:\n#{$!}" )
  end

  # save the new data in the database
  db_conn.transaction do
    begin
      rows_updated = genbank_files.filter( :id.qualify(:genbank_files) => genbank_file[:id] ).update(
        :escell_clone     => data[:escell_clone],
        :targeting_vector => data[:targeting_vector]
      )
      log.info( "Updated genbank_file (#{ genbank_file[:id] })" ) if rows_updated
    rescue
      raise(Sequel::Rollback.new($!))
    end

    raise(Sequel::Rollback) if @debug
  end

  exit if @debug # @DEBUGGING
end
