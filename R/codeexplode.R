#' @importFrom rlang .data

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
---


```{r, include = F}
# This is the recommended set up for flipbooks
# you might think about setting cache to TRUE as you gain practice --- building flipbooks from scratch can be time consuming
knitr::opts_chunk$set(fig.width = 6, message = F, warning = FALSE, comment = "", cache = F)

options(tibble.print_min = 55)
options(knitr.duplicate.label = "allow")
options(width=300) # prevents data wrapping 
```


```{css, eval = TRUE, echo = FALSE}
.remark-code{line-height: 1.5; font-size: 40%}

@media print {
  .has-continuation {
    display: block;
  }
}

code.r.hljs.remark-code{
  position: relative;
  overflow-x: hidden;
}


code.r.hljs.remark-code:hover{
  overflow-x:visible;
  width: 500px;
  border-style: solid;
}
```

'

}

write_inline_chunk_reveal <- function(chunk_name){

paste0('`r flipbookr::chunk_reveal("', chunk_name, '", left_assign = "detect")`')

}

chunks_to_include_equals_false <- function(x){

stringr::str_replace(x, '```{r .+, ', '```')

}

rmd_read_as_table <- function(rmd_path = "README.Rmd"
                              ){

rmd_path %>%
    readLines() ->
my_lines

    tibble::tibble(lines = my_lines)

}


#' Title
#'
#' @param r_script_path
#'
#' @return
#' @export
#'
#' @importFrom rlang .data
r_read_as_rmd_table <- function(r_script_path = "docs/r_script_test.R"){

  r_script_path %>%
    readr::read_file() %>%
    paste("```{r name, include = FALSE}",.,"```", sep = "\n") %>%
    stringr::str_replace_all("\\r\\n\\r\\n\\r\\n|\\n\\n\\n", "\\\n```\\\n\\\n```{r name, include = FALSE}\\\n") %>%
    readr::read_lines() ->
  the_lines

  tibble::tibble(lines = the_lines) %>%
    dplyr::mutate(is_chunk_start = stringr::str_detect(.data$lines, "^```\\{r name,")) %>%
    dplyr::mutate(which_chunk = cumsum(.data$is_chunk_start)) %>%
    dplyr::mutate(lines = stringr::str_replace(.data$lines, "```\\{r name,", paste0("```{r name_", .data$which_chunk, ",")))

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
                          paste0("---\n\n\n", write_inline_chunk_reveal(chunk_name = .data$chunk_name),
                                 "\n\n\n", .data$lines), .data$lines))

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

r_prepped_table_write_exploded_code_rmd <- function(prepped_table, rmd_output = "explodedcode.Rmd"){

  prepped_table %>%
    # rmd_table_remove_yaml() %>%
    dplyr::pull(.data$lines) %>%
    paste(collapse = "\n") ->
    rmd_body

  paste(write_yaml(), rmd_body, sep = "\n") %>%
    writeLines(con = rmd_output)

}


#' Rmarkdown file as input, returns rmd prepped to flipbook
#'
#' @param rmd_path a file path, character string
#' @param rmd_output a file path, where to save rmd
#' @param render if true, render
#'
#' @return
#' @export
#'
rmd_code_explode <- function(rmd_path = "README.Rmd",
                             rmd_output = "explodedcode.Rmd",
                             render = F){

  rmd_path %>%
    rmd_read_as_table() %>%
    rmd_table_find_chunk_name_set_include_to_false() %>%
    rmd_table_w_chunk_name_add_flip_inline() %>%
    rmd_table_remove_yaml() %>%  #needed?
    prepped_table_write_exploded_code_rmd(rmd_output = rmd_output)

  if(render == TRUE){
  rmarkdown::render(rmd_output)
  }
}




#' Title
#'
#' @param r_script_path path to .Rmd script
#' @inheritParams rmd_code_explode
#'
#' @return
#' @export
#'
r_code_explode <- function(r_script_path = "docs/r_script_test.R",
                           rmd_output = "explodedcode.Rmd",
                           render = F){

  r_script_path %>%
    r_read_as_rmd_table() %>%
    rmd_table_find_chunk_name_set_include_to_false() %>%
    rmd_table_w_chunk_name_add_flip_inline() %>%
    # rmd_table_remove_yaml() %>%
    r_prepped_table_write_exploded_code_rmd(rmd_output = rmd_output)

  if(render == TRUE){
    rmarkdown::render(rmd_output)
  }

}


