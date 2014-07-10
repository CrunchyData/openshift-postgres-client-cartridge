%global cartridgedir %{_libexecdir}/openshift/cartridges/crunchypg-client-cart

Summary:       Provides Crunchy Postgres HA client cart
Name:          openshift-postgres-client-cartridge
Version:       1.0.7
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
%doc %{cartridgedir}/crunchy.LICENSE

%changelog
* Thu Jul 10 2014 jeff mccormick <jeffmc04@gmail.com> 1.0.7-1
- fix for ose2.1 (jeffmc04@gmail.com)

* Tue Jun 24 2014 jeff mccormick <jeffmc04@gmail.com> 1.0.6-1
- Merge branch 'master' of github.com:crunchyds/openshift-postgres-client-
  cartridge (jeffmc@localhost.localdomain)
- added add-standby-node script (jeffmc@localhost.localdomain)

* Sun Jun 22 2014 jeff mccormick <jeffmc04@gmail.com> 1.0.5-1
- updated with feedback (jeffmc@localhost.localdomain)
- Merge branch 'master' of github.com:crunchyds/openshift-postgres-client-
  cartridge (jeffmc@localhost.localdomain)
- fix LD_LIBRARY_PATH setting for ose2.1 (jeffmc@localhost.localdomain)

* Tue May 13 2014 jeff mccormick <jeffmc04@gmail.com> 1.0.4-1
- 

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

