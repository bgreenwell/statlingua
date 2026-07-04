if (requireNamespace("tinytest", quietly = TRUE)){
  home <- length(unclass(packageVersion("statlingo"))[[1L]]) == 4L
  tinytest::test_package("statlingo", at_home = home)
}
