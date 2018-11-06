#
# spec file for package yast2-firewall
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-firewall
Version:        4.0.34
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0
BuildRequires:  perl-XML-Writer update-desktop-files yast2-testsuite
BuildRequires:  yast2-devtools >= 3.1.10

# Y2Firewall::Firewalld#reset
BuildRequires:  yast2 >= 4.0.98
BuildRequires:  rubygem(%rb_default_ruby_abi:yast-rake)
BuildRequires:  rubygem(%rb_default_ruby_abi:rspec)

# Y2Firewall::Firewalld#reset
Requires:       yast2 >= 4.0.98

# ButtonBox widget
Conflicts:	yast2-ycp-ui-bindings < 2.17.3

Provides:	yast2-config-firewall
Obsoletes:	yast2-config-firewall
Provides:	yast2-trans-firewall
Obsoletes:	yast2-trans-firewall

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - Firewall Configuration

%description
A YaST2 module to be used for configuring a firewall.

%prep
%setup -n %{name}-%{version}

%check
rake test:unit

%build

%install
rake install DESTDIR="%{buildroot}"

%files
%defattr(-,root,root)
%{yast_dir}/clients/*.rb
%{yast_dir}/lib
%{yast_dir}/include
%{yast_dir}/modules
%{yast_desktopdir}/*.desktop
%{yast_schemadir}/autoyast/rnc/firewall.rnc

%doc COPYING
%doc README.md
%doc CONTRIBUTING.md
