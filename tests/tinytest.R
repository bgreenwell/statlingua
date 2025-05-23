if (requireNamespace("tinytest", quietly = TRUE)){
  home <- length(unclass(packageVersion("statlingua"))[[1L]]) == 4L
  tinytest::test_package("statlingua", at_home = home)
}
