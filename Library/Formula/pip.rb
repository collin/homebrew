require 'formula'

class Setuptools <Formula
  url 'http://pypi.python.org/packages/source/s/setuptools/setuptools-0.6c11.tar.gz'
  homepage 'http://pypi.python.org/pypi/setuptools'
  md5 '7df2a529a074f613b509fb44feefe74e'
  version '0.6c11'
end

class Pip <Formula
  url 'http://pypi.python.org/packages/source/p/pip/pip-0.6.3.tar.gz'
  homepage 'http://pip.openplans.org/'
  md5 '0602fa9179cfaa98e41565d4a581d98c'

  def script lib_path
    <<-EOS
#!/usr/bin/env python
"""
This is the Homebrew pip wrapper
"""
import sys
sys.path.insert(0, '#{lib_path}')
from pip import main

if __name__ == '__main__':
    main()
    EOS
  end

  def patches
    # better default paths for build, source-cache and log locations
    DATA
  end

  def install
    python_version = `python -V 2>&1`.match('Python (\d+\.\d+)').captures.at(0)
    site_packages = prefix+'site-packages'

    site_packages.mkpath

    Setuptools.new.brew do |f|
      setuptools_version = f.version
      mv 'setuptools', site_packages
      mv 'setuptools.egg-info/PKG-INFO', "#{site_packages}/setuptools-#{setuptools_version}-py#{python_version}.egg"
    end

    # make sure we use the right python (distutils rewrites the shebang)
    # also adds the pip lib path to the PYTHONPATH
    (bin+'pip').write(script(site_packages))

    mv 'pip', site_packages
    mv 'pip.egg-info/PKG-INFO', "#{site_packages}/pip-#{version}-py#{python_version}.egg-info"
  end

  def two_line_instructions
    "pip installs packages. Python packages.\n"+
    "Run 'pip help' to see a list of commands."
  end

  def caveats
    # I'm going to add a proper two_line_instructions formula function at some point
    two_line_instructions
  end
end

__END__
diff --git a/pip/baseparser.py b/pip/baseparser.py
index 149c52d..82ffa46 100755
--- a/pip/baseparser.py
+++ b/pip/baseparser.py
@@ -186,7 +186,7 @@ parser.add_option(
     '--local-log', '--log-file',
     dest='log_file',
     metavar='FILENAME',
-    default='./pip-log.txt',
+    default=os.getenv('HOME')+'/Library/Logs/pip.log',
     help=optparse.SUPPRESS_HELP)
 
 parser.add_option(
diff --git a/pip/locations.py b/pip/locations.py
index bd70d92..e517292 100755
--- a/pip/locations.py
+++ b/pip/locations.py
@@ -4,19 +4,20 @@ import sys
 import os
 from distutils import sysconfig
 
+user_dir = os.path.expanduser('~')
+
 if getattr(sys, 'real_prefix', None):
     ## FIXME: is build/ a good name?
     build_prefix = os.path.join(sys.prefix, 'build')
     src_prefix = os.path.join(sys.prefix, 'src')
 else:
-    ## FIXME: this isn't a very good default
-    build_prefix = os.path.join(os.getcwd(), 'build')
-    src_prefix = os.path.join(os.getcwd(), 'src')
+    build_prefix = user_dir + '/.pip/build'
+    src_prefix = user_dir + '/.pip/sources'
 
 # FIXME doesn't account for venv linked to global site-packages
 
 site_packages = sysconfig.get_python_lib()
-user_dir = os.path.expanduser('~')
+
 if sys.platform == 'win32':
     bin_py = os.path.join(sys.prefix, 'Scripts')
     # buildout uses 'bin' on Windows too?
