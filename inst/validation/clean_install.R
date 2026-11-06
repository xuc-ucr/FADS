# Run from a FRESH R session. Set package_path to the unzipped FADS directory.
# Avoid devtools::load_all() before checking installed package behavior.
stopifnot(file.exists(file.path(package_path, 'DESCRIPTION')))
if ('package:FADS' %in% search()) detach('package:FADS', unload=TRUE, character.only=TRUE)
if ('FADS' %in% loadedNamespaces()) try(unloadNamespace('FADS'), silent=TRUE)
lib <- .libPaths()[1]
if ('FADS' %in% rownames(utils::installed.packages(lib.loc=lib)))
  utils::remove.packages('FADS', lib=lib)
utils::install.packages(package_path, repos=NULL, type='source', lib=lib,
                        INSTALL_opts=c('--preclean', '--no-multiarch'))
cat('Installed at:', find.package('FADS'), '\n')
cat('Installed version:', as.character(utils::packageVersion('FADS')), '\n')
stopifnot(as.character(utils::packageVersion('FADS')) == '0.3.6')
stopifnot('bandwidth_method' %in% names(formals(FADS::fads)))
cat('PASS: Installed function exposes bandwidth_method\n')
