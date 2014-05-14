%global cartridgedir %{_libexecdir}/openshift/cartridges/crunchypg-client-cart

Summary:       Provides Crunchy Postgres HA client cart
Name:          openshift-postgres-client-cartridge
Version:       1.0.3
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       file:///./%{name}-%{version}.tar.gz
Requires:      lsof
Requires:      bc
Requires:      /bin/sh

%description
Provides postgres haclient cart

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%post

%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}


%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/LICENSE

%changelog
* Tue May 13 2014 jeff mccormick <jeffmc04@gmail.com> 1.0.3-1
- new package built with tito

* Tue Mar 18 2014 Unknown name 0.0.6-1
- fix (jeffmc@localhost.localdomain)

* Tue Mar 18 2014 Unknown name 0.0.5-1
- fix (jeffmc@localhost.localdomain)

* Tue Mar 18 2014 Unknown name 0.0.4-1
- fixed (jeffmc@localhost.localdomain)

* Tue Mar 18 2014 Unknown name 0.0.3-1
- fix spec (jeffmc@localhost.localdomain)

* Tue Mar 18 2014 Unknown name 0.0.2-1
- new package built with tito

