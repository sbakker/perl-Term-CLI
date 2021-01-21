# Fedora Build Dependencies

## Dist::Zilla packages needed:

```
perl-Dist-Zilla
perl-Dist-Zilla-Plugin-VersonFromMainModule
perl-Dist-Zilla-Plugin-CheckChangesHasContent
perl-Dist-Zilla-Plugin-GithubMeta
perl-Dist-Zilla-Plugin-CopyFilesFromBuild
```

## Other Build dependencies

```
perl-Perl-PrereqScanner
perl-Pod-Coverage-TrustPod
perl-Test-Class
perl-Test-Exception
perl-Test-Output
```

## Non-standard Dist::Zilla

Either self-build, or comment out in dist.ini.

```
perl-Dist-Zilla-Plugin-MetaProvides-Package
```
