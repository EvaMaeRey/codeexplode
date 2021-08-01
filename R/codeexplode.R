write_yaml <- function(){

'---
title: "Exploded code"
subtitle: "Using flipbookr and xaringan"
author: "Me"
output:
  xaringan::moon_reader:
    lib_dir: libs
    css: [default, hygge, ninjutsu]
    nature:
      ratio: 16:9
      highlightStyle: github
      highlightLines: true
      countIncrementalSlides: false
---'

}

write_inline_chunk_reveal <- function(chunk_name){

paste0('`r flipbookr::chunk_reveal("', chunk_name, '")`')

}

chunks_to_include_equals_false <- function(x){

stringr::str_replace(x, '```{r .+, ', '```')


}

rmd_read_as_table <- function(rmd_path = "README.Rmd"
                              ){

rmd_path %>%
    readLines() %>%
    tibble::tibble(lines = .)

}


rmd_table_remove_yaml <- function(rmd_table = rmd_read_as_table("README.Rmd")){

  rmd_table %>%
    dplyr::mutate(ind_three_dashes = stringr::str_detect(.data$lines, "^---$")) %>%
    dplyr::mutate(far_along = cumsum(.data$ind_three_dashes)) %>%
    dplyr::filter(.data$far_along != 1) %>%
    dplyr::slice(-1)

}


rmd_table_find_chunk_name_set_include_to_false <- function(rmd_table = rmd_read_as_table("README.Rmd")){

  rmd_table %>%
    dplyr::mutate(ind_chunk_start = stringr::str_detect(.data$lines, "^```\\{")) %>%
    dplyr::mutate(ind_include_already_false =
                    stringr::str_detect(.data$lines, "include ?= ?F")) %>%
    dplyr::mutate(ind_chunk_end = stringr::str_detect(.data$lines, "^```$")) %>%
    dplyr::mutate(chunk_name = stringr::str_extract(.data$lines, "^```\\{r \\w+")) %>%
    dplyr::mutate(chunk_name = stringr::str_remove(.data$chunk_name, "^```\\{r ")) %>%
    dplyr::mutate(lines = ifelse(.data$ind_chunk_start & !.data$ind_include_already_false,
                                 stringr::str_replace(.data$lines, "\\}", ", include = FALSE\\}"), .data$lines))

}

rmd_table_w_chunk_name_add_flip_inline <- function(rmd_table_w_chunk_name){

  rmd_table_w_chunk_name %>%
    dplyr::mutate(lines = ifelse(.data$ind_chunk_start,
                          paste0("---\n\n", write_inline_chunk_reveal(chunk_name = .data$chunk_name),
                                 "\n\n---\n\n", .data$lines), .data$lines))

}

prepped_table_write_exploded_code_rmd <- function(prepped_table, rmd_output = "explodedcode.Rmd"){

  prepped_table %>%
    rmd_table_remove_yaml() %>%
    dplyr::pull(.data$lines) %>%
    paste(collapse = "\n") ->
  rmd_body

  paste(write_yaml(), rmd_body, sep = "\n") %>%
    writeLines(con = rmd_output)

}


#' Title
#'
#' @param rmd_path
#' @param rmd_output
#' @param render
#'
#' @return
#' @export
#'
#' @examples
rmd_code_explode <- function(rmd_path = "README.Rmd",
                             rmd_output = "explodedcode.Rmd",
                             render = F){

  rmd_path %>%
    rmd_read_as_table() %>%
    rmd_table_find_chunk_name_set_include_to_false() %>%
    rmd_table_w_chunk_name_add_flip_inline() %>%
    rmd_table_remove_yaml() %>%
    prepped_table_write_exploded_code_rmd(rmd_output = rmd_output)

}
