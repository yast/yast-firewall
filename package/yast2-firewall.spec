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

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#


Name:           yast2-firewall
Version:        4.2.0
Release:        0
Summary:        YaST2 - Firewall Configuration
Group:          System/YaST
License:        GPL-2.0-only
Url:            https://github.com/yast/yast-firewall

Source0:        %{name}-%{version}.tar.bz2

BuildRequires:  perl-XML-Writer update-desktop-files yast2-testsuite
BuildRequires:  yast2-devtools >= 3.1.10
# Removed zone name from common attributes definition
BuildRequires:  yast2 >= 4.1.67
BuildRequires:  rubygem(%rb_default_ruby_abi:yast-rake)
BuildRequires:  rubygem(%rb_default_ruby_abi:rspec)

# Removed zone name from common attributes definition
Requires:       yast2 >= 4.1.67
Requires:       yast2-ruby-bindings >= 1.0.0

# ButtonBox widget
Conflicts:      yast2-ycp-ui-bindings < 2.17.3
# CpiMitigations
Conflicts:      yast2-bootloader < 4.2.1

Provides:       yast2-config-firewall
Provides:       yast2-trans-firewall

Obsoletes:      yast2-config-firewall
Obsoletes:      yast2-trans-firewall

BuildArch:      noarch

%description
A YaST2 module to be used for configuring a firewall.

%prep
%setup -q

%check
%yast_check

%build

%install
%yast_install
%yast_metainfo

%files
%{yast_clientdir}
%{yast_libdir}
%{yast_desktopdir}
%{yast_metainfodir}
%{yast_schemadir}
%{yast_icondir}
%license COPYING
%doc README.md
%doc CONTRIBUTING.md
