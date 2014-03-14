require 'rake/clean'
require 'rake/packagetask'
require 'fcntl'

require_relative 'Scripts/console'

#
# TODO: deliverables should live in INTERMEDIATESDIR until the very last possible moment, when they have been fully verified.
#

# SHELL_IS_LOGIN = STDIN.fcntl(Fcntl::F_GETFL, 0) != 0
# if SHELL_IS_LOGIN
#   XCODE_BUILD_FILTER = "| xcpretty -c"
#   XCODE_TEST_FILTER = "| xcpretty -tc"
# else
  # Console.puts "Non-login shell detected, disabling pretty printing"
  XCODE_BUILD_FILTER = ""
  XCODE_TEST_FILTER = ""
# end

#
# Constants
#

DEVELOPER_ID = "Scott Perry"

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

BRANCH = `git symbolic-ref HEAD | sed -e 's|^refs/heads/||'`.strip

#
# Synthesized
#

BRANCH_IS_RELEASE = RELEASE_BRANCHES.include?(BRANCH)

BRANCH_IS_GM = (BRANCH == "master")

DELIVERABLE_ARCHIVE = File.absolute_path("#{BUILDDIR}/#{PRODUCT}.xcarchive")

DELIVERABLE_APP = File.absolute_path("#{BUILDDIR}/#{PRODUCT}.app")

DELIVERABLE_ZIP = File.absolute_path("#{BUILDDIR}/#{PRODUCT}.zip")

def formatted_fail(message)
  fail Console.background_red(Console.white(message))
end

def check_ruby_version
  ruby_version = RUBY_VERSION.split('.')
  required_version = '2.0.0'.split('.')
  formatted_fail "#{deliverable_path} wasn't produced!" if ruby_version.count > 3
  (0..(ruby_version.count - 1)).each do |index|
    if ruby_version[index] < required_version[index]
      formatted_fail "Sorry, this Rakefile requires Ruby #{required_version.join('.')} or newer."
    elsif ruby_version[index] > required_version[index]
      break
    end
  end
end
check_ruby_version

# TODO: better way to get homedir here.
CLOBBER.include(FileList["/Users/#{`whoami`.strip}/Library/Developer/Xcode/DerivedData/#{PRODUCT}-*"])
CLOBBER.include(DERIVEDDATA)

CLEAN.include(FileList[BUILDDIR])

XCODEFLAGS = [
  "-workspace \"#{PRODUCT}.xcworkspace\"",
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
    Console.puts ' ____________________________________ '
    Console.puts '/ WARNING: not able to sign app      \\'
    Console.puts '| deliverable for appcast! Find this |'
    Console.puts '\\ message in the Rakefile.           /'
    Console.puts ' ------------------------------------ '
    Console.puts '        \\   ^__^                      '
    Console.puts '         \\  (oo)\\_______              '
    Console.puts '            (__)\\       )\\/\\          '
    Console.puts '                ||----w |             '
    Console.puts '                ||     ||             '
    sleep 5
  else
    return `Scripts/sign_update.rb \"#{archive}\" \"#{private_key}\"`.strip
  end
end

def verify_codesign(app_path)
  shell "codesign --verify --verbose --deep \"#{app_path}\""
  shell "spctl --assess --verbose=4 --type execute \"#{app_path}\""
end

def verify_deliverable(deliverable_path)
  formatted_fail "#{deliverable_path} wasn't produced!" unless File.exists? deliverable_path
end

directory BUILDDIR
directory DERIVEDDATA
directory INTERMEDIATESDIR

task :default => [:analyze, :test]

task :deps do
  echo_step "Installing/updating dependencies"
  # Rakefile deps
  shell "gem install xcpretty --no-ri --no-rdoc" if SHELL_IS_LOGIN
  
  # Submodules
  shell "git submodule sync"
  shell "git submodule update --init --recursive"

  # Pods
  shell "gem install cocoapods --no-ri --no-rdoc"
  shell "pod install"
end

def xcode(action)
  run_task DERIVEDDATA
  shell "set -e; set -o pipefail; xcodebuild #{XCODEFLAGS} #{action} 2>&1 #{XCODE_BUILD_FILTER}"
end

def shell(action)
  Console.puts(Console.bold(Console.black("#{action}")))
  formatted_fail "Shell command failed: #{action}" unless system(action)
end

def shell_non_fatal(action)
  Console.puts(Console.bold(Console.black("#{action}")))
  return system(action)
end

def echo_step(step)
  Console.puts(Console.bold(Console.black(Console.background_white(step))))
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
  echo_step("Testing #{PRODUCT}.xcworkspace")
  def test_scheme(scheme)
    shell "set -e; set -o pipefail; xcodebuild -scheme \"#{scheme}\" -workspace \"#{PRODUCT}.xcworkspace\" -configuration \"Debug\" -derivedDataPath \"#{DERIVEDDATA}\" test 2>&1 #{XCODE_TEST_FILTER}"
  end

  test_scheme("Switch")
  test_scheme("ReactiveCocoa")
  test_scheme("NNKit")
  test_scheme("Sparkle")
end


 # :archive "Builds #{PRODUCT}.xcarchive in #{BUILDDIR}"
task :archive => [DELIVERABLE_ARCHIVE]
task DELIVERABLE_ARCHIVE => [File.dirname(DELIVERABLE_ARCHIVE)] do
  echo_step("Building archive bundle: #{File.basename(DELIVERABLE_ARCHIVE)}")

  archive_path = DELIVERABLE_ARCHIVE.slice(0..(DELIVERABLE_ARCHIVE.rindex('.') - 1))
  xcode "-archivePath \"#{archive_path}\" archive"
  verify_deliverable DELIVERABLE_ARCHIVE
  
  Console.puts "Finished: #{Console.green(DELIVERABLE_ARCHIVE)}\n"
end

task :app => [DELIVERABLE_APP]
task DELIVERABLE_APP => [DELIVERABLE_ARCHIVE, File.dirname(DELIVERABLE_APP)] do
  echo_step("Building application bundle: #{File.basename(DELIVERABLE_APP)}")
  
  FileUtils.rm_r DELIVERABLE_APP if File.exist? DELIVERABLE_APP
  
  app_path = DELIVERABLE_APP.slice(0..(DELIVERABLE_APP.rindex('.') - 1))
  shell "xcodebuild -exportArchive -exportFormat APP -archivePath \"#{DELIVERABLE_ARCHIVE}\" -exportPath \"#{app_path}\""
  
  verify_deliverable DELIVERABLE_APP

  if shell_non_fatal "codesign --force --deep --sign \"Developer ID Application: #{DEVELOPER_ID}\" \"#{DELIVERABLE_APP}\""
    verify_codesign DELIVERABLE_APP
  else
    # If you're here, chances are DEVELOPER_ID isn't set correctly. It's at the top of this file, and should be set to the company name of your Developer ID certificate.
    Console.puts ' _____________________________________ '
    Console.puts '/ WARNING: unable to sign app         \\'
    Console.puts '| deliverable with Developer ID!       |'
    Console.puts '\\ Find this message in the Rakefile.  /'
    Console.puts ' ------------------------------------- '
    Console.puts '        \\   ^__^                       '
    Console.puts '         \\  (oo)\\_______               '
    Console.puts '            (__)\\       )\\/\\           '
    Console.puts '                ||----w |              '
    Console.puts '                ||     ||              '
  end
  
  Console.puts "Finished: #{Console.green(DELIVERABLE_APP)}\n"
end

task :zip => [DELIVERABLE_ZIP]
task DELIVERABLE_ZIP => [DELIVERABLE_APP, File.dirname(DELIVERABLE_ZIP), INTERMEDIATESDIR] do
  echo_step("Building zip archive: #{File.basename(DELIVERABLE_ZIP)}")
  
  FileUtils.rm DELIVERABLE_ZIP if File.exist? DELIVERABLE_ZIP
  shell "cd \"#{File.dirname(DELIVERABLE_APP)}\" && zip --symlinks -rq9o \"#{DELIVERABLE_ZIP}\" \"#{File.basename(DELIVERABLE_APP)}\""
  verify_deliverable DELIVERABLE_ZIP
  
  # Verify that zip didn't ruin code signing (this happened to Switch 0.0.6)
  unzipped_app = "#{INTERMEDIATESDIR}/#{File.basename(DELIVERABLE_APP)}"
  FileUtils.rm_r unzipped_app if File.exist? unzipped_app
  shell "cd \"#{INTERMEDIATESDIR}\" && unzip -q \"#{DELIVERABLE_ZIP}\""
  verify_deliverable unzipped_app
  
  # Verify that unzipped app and app deliverable do not differ.
  shell "diff -r \"#{unzipped_app}\" \"#{DELIVERABLE_APP}\""
  # Verify unzipped application launches successfully.
  shell "open \"#{unzipped_app}\""
  # grep for "[/]Users/foo/bar" to prevent grep from showing up in the list of processes matching the query.
  match = "[#{unzipped_app[0]}]#{unzipped_app[1..-1]}"
  shell "ps auxwww | grep \"#{match}\" | awk '{ print $2; }' | xargs kill"
  
  unless shell_non_fatal "spctl --assess --verbose=4 --type execute \"#{unzipped_app}\""
    Console.puts Console.background_red(Console.white("WARNING: The application bundle inside #{File.basename(DELIVERABLE_ZIP)} is not properly code signed and is not suitable for distribution!"))
  end
  
  # Clean up
  FileUtils.rm_r unzipped_app
  
  Console.puts "Finished: #{Console.green(DELIVERABLE_ZIP)}\n"
end

task :release => [:analyze, :test] do
  # TODO
  # formatted_fail "Releases can only be made from branches: #{RELEASE_BRANCHES.inspect}" unless BRANCH_IS_RELEASE

  gst = 'git status -uno --ignore-submodules=untracked'
  formatted_fail "Uncommitted files detected!\n#{`#{gst} --short`}" unless `#{gst} --porcelain | wc -l`.strip == "0"
  
  run_task DELIVERABLE_ZIP
  # The zip's contents can be unsigned, but a release must be signed!
  verify_codesign DELIVERABLE_APP
  
end
