require 'rake/clean'
require 'rake/packagetask'

require_relative 'Scripts/console'

class String
  # Returns a new string that has the leading and trailing whitespace trimmed.
  def trim
    tmp = self
    tmp.strip!
    return tmp
  end
end

#
# Constants
#

RELEASE_BRANCHES = ["develop", "master"]

BUILDDIR = File.absolute_path("Build")

INTERMEDIATESDIR = "#{BUILDDIR}/Intermediates"

DERIVEDDATA = File.absolute_path("DerivedData")

#
# Environmental
#

# Switch.xcodeproj
PROJECT = FileList['*.xcodeproj'][0]

# Switch
PRODUCT = PROJECT.slice(0..(PROJECT.index('.') - 1))

BRANCH = `git symbolic-ref HEAD | sed -e 's|^refs/heads/||'`.trim

#
# Synthesized
#

BRANCH_IS_RELEASE = RELEASE_BRANCHES.include?(BRANCH)

BRANCH_IS_GM = (BRANCH == "master")

DELIVERABLE_ARCHIVE = File.absolute_path("#{BUILDDIR}/#{PRODUCT}.xcarchive")

DELIVERABLE_APP = File.absolute_path("#{BUILDDIR}/#{PRODUCT}.app")

DELIVERABLE_ZIP = File.absolute_path("#{BUILDDIR}/#{PRODUCT}.zip")

# TODO: better way to get homedir here.
CLOBBER.include(FileList["/Users/#{`whoami`.trim}/Library/Developer/Xcode/DerivedData/#{PRODUCT}-*"])
CLOBBER.include(DERIVEDDATA)

CLEAN.include(FileList[BUILDDIR])

XCODEFLAGS = [
  "-project \"#{PROJECT}\"",
  "-scheme \"#{PRODUCT}\"",
  "-derivedDataPath \"#{DERIVEDDATA}\"",
].join(' ')

#
# Helpers
#

def run_task(task, args=nil)
  if args.nil?
    Rake::Task[task].invoke
  else
    Rake::Task[task].invoke(args)
  end
end

def sparkle_signature(archive)
  # TODO: Sorry.
  private_key = "Secrets-local/Sparkle.dsa_priv.pem"
  unless File.exist?(private_key)
    sh 'echo -e "WARNING: not able to sign app deliverable for appcast!\nFind this message in the Rakefile." | cowsay'
    sleep 5
  else
    return `Scripts/sign_update.rb \"#{archive}\" \"#{private_key}\"`.trim
  end
end

def verify_codesign(app_path)
  sh "codesign --verify --verbose --deep \"#{app_path}\""
  sh "spctl --assess --type execute \"#{app_path}\""
  puts "#{app_path}: #{Console.green("has a valid code signature")}"
end

def verify_deliverable(deliverable_path)
  fail "💩  #{deliverable_path} wasn't produced!" unless File.exists? deliverable_path
  puts "#{deliverable_path}: #{Console.green("exists")}"
end

directory BUILDDIR
directory DERIVEDDATA
directory INTERMEDIATESDIR

task :default => [:analyze, :test]

def xcode(action)
  run_task DERIVEDDATA
  sh "set -e; set -o pipefail; xcodebuild #{XCODEFLAGS} #{action} | Scripts/xcodebuild_prettify.rb"
end

# can these just be tasks dependant on another task with an argument?
task :analyze do
  xcode "analyze"
end

task :build do
  xcode "build"
end

task :clean do
  xcode "clean"
end

task :test do
  sh "set -e; set -o pipefail; xcodebuild -scheme \"Switch\" -project \"#{PROJECT}\" -derivedDataPath \"#{DERIVEDDATA}\" test # | Scripts/xcodebuild_prettify.rb"
  sh "set -e; set -o pipefail; xcodebuild -scheme \"ReactiveCocoa\" -project \"#{PROJECT}\" -derivedDataPath \"#{DERIVEDDATA}\" test # | Scripts/xcodebuild_prettify.rb"
  sh "set -e; set -o pipefail; xcodebuild -scheme \"NNKit\" -project \"#{PROJECT}\" -derivedDataPath \"#{DERIVEDDATA}\" test # | Scripts/xcodebuild_prettify.rb"
  sh "set -e; set -o pipefail; xcodebuild -scheme \"Sparkle\" -project \"#{PROJECT}\" -derivedDataPath \"#{DERIVEDDATA}\" test # | Scripts/xcodebuild_prettify.rb"
end


 # :archive "Builds #{PRODUCT}.xcarchive in #{BUILDDIR}"
task :archive => [DELIVERABLE_ARCHIVE]
task DELIVERABLE_ARCHIVE => [File.dirname(DELIVERABLE_ARCHIVE)] do
  Console.puts(Console.bold(Console.black("Building archive bundle: #{File.basename(DELIVERABLE_ARCHIVE)}")))

  archive_path = DELIVERABLE_ARCHIVE.slice(0..(DELIVERABLE_ARCHIVE.rindex('.') - 1))
  xcode "-archivePath \"#{archive_path}\" archive"
  
  verify_deliverable DELIVERABLE_ARCHIVE
end

task :app => [DELIVERABLE_APP]
task DELIVERABLE_APP => [DELIVERABLE_ARCHIVE, File.dirname(DELIVERABLE_APP)] do
  Console.puts(Console.bold(Console.black("Building application bundle: #{File.basename(DELIVERABLE_APP)}")))
  
  FileUtils.rm_r DELIVERABLE_APP if File.exist? DELIVERABLE_APP
  
  app_path = DELIVERABLE_APP.slice(0..(DELIVERABLE_APP.rindex('.') - 1))
  sh "xcodebuild -exportArchive -exportFormat APP -archivePath \"#{DELIVERABLE_ARCHIVE}\" -exportPath \"#{app_path}\""
  
  verify_deliverable DELIVERABLE_APP

  # TODO: if you're not numist and you want to sign an app for distribution you're gonna wanna change this.
  if `whoami`.trim == "numist"
    sh "codesign --force --deep --sign \"Developer ID Application: Scott Perry\" \"#{DELIVERABLE_APP}\""
    verify_codesign DELIVERABLE_APP
  else
    sh 'echo -e "WARNING: not able to sign app deliverable with Developer ID!\nFind this message in the Rakefile." | cowsay'
    sleep 5
  end
end

task :zip => [DELIVERABLE_ZIP]
task DELIVERABLE_ZIP => [DELIVERABLE_APP, File.dirname(DELIVERABLE_ZIP), INTERMEDIATESDIR] do
  Console.puts(Console.bold(Console.black("Building zip archive: #{File.basename(DELIVERABLE_ZIP)}")))
  
  FileUtils.rm DELIVERABLE_ZIP if File.exist? DELIVERABLE_ZIP
  sh "cd \"#{File.dirname(DELIVERABLE_APP)}\" && zip --symlinks -rq9o \"#{DELIVERABLE_ZIP}\" \"#{File.basename(DELIVERABLE_APP)}\""
  verify_deliverable DELIVERABLE_ZIP
  
  # Verify that zip didn't ruin code signing (this happened to Switch 0.0.6)
  Console.puts(Console.bold(Console.black("Verifying contents of zip archive...")))
  unzipped_app = "#{INTERMEDIATESDIR}/#{File.basename(DELIVERABLE_APP)}"
  FileUtils.rm_r unzipped_app if File.exist? unzipped_app
  sh "cd \"#{INTERMEDIATESDIR}\" && unzip -q \"#{DELIVERABLE_ZIP}\""
  verify_deliverable unzipped_app
  
  # The app deliverable should have had its code signature checked, but double check just in case.
  verify_codesign unzipped_app
  # Verify that unzipped app and app deliverable do not differ.
  sh "diff -r \"#{unzipped_app}\" \"#{DELIVERABLE_APP}\""
  Console.puts "#{DELIVERABLE_ZIP}: #{Console.green("properly represents #{File.basename(DELIVERABLE_APP)}")}"
  
  # Verify unzipped application launches successfully.
  sh "open \"#{unzipped_app}\""
  # grep for "[/]Users/foo/bar" to prevent grep from showing up in the list of processes matching the query.
  match = "[#{unzipped_app[0]}]#{unzipped_app[1..-1]}"
  sh "ps auxwww | grep \"#{match}\" | awk '{ print $2; }' | xargs kill"
  Console.puts "#{unzipped_app}: #{Console.green("launched successfully")}"
  
  # Clean up
  FileUtils.rm_r unzipped_app
  
end

task :release => [:analyze, :test] do
  # TODO
  # fail "💩  Releases can only be made from branches: #{RELEASE_BRANCHES.inspect}" unless BRANCH_IS_RELEASE

  gst = 'git status -uno --ignore-submodules=untracked'
  fail "💩  Uncommitted files detected!\n#{`#{gst} --short`}" unless `#{gst} --porcelain | wc -l`.trim == "0"
  
  run_task DELIVERABLE_ZIP
  
end

task :noop
