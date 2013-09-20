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
Version:        3.1.0
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0
BuildRequires:  perl-XML-Writer update-desktop-files yast2-testsuite
BuildRequires:  yast2-devtools >= 3.0.6
# IP::CheckNetwork
BuildRequires:	yast2 >= 2.23.25

# IP::CheckNetwork
Requires:	yast2 >= 2.23.25

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

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/firewall
%{yast_yncludedir}/firewall/*
%{yast_moduledir}/SuSEFirewall*
%{yast_clientdir}/firewall*
%{yast_desktopdir}/firewall.desktop
%{yast_schemadir}/autoyast/rnc/firewall.rnc
%doc %{yast_docdir}
