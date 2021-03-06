
<!-- README.md is generated from README.Rmd. Please edit that file -->
**qgg**
-------

### An R package for Quantitative Genetic and Genomic analyses

**qgg** provides an infrastructure for efficient processing of large-scale genetic and phenotypic data including core functions for: \* fitting linear mixed models \* constructing marker-based genomic relationship matrices \* estimating genetic parameters (heritability and correlation) \* performing genomic prediction and genetic risk profiling \* single or multi-marker association analyses

The **qgg** package was developed based on the hypothesis that certain regions on the genome, so-called *genomic features*, may be enriched for causal variants affecting the trait. Several genomic feature classes can be formed based on previous studies and different sources of information including genes, chromosomes, biological pathways, gene ontologies, sequence annotation, prior QTL regions, or other types of external evidence.

The **qgg** package provides a range of genomic feature modeling approaches implemented using likelihood or Bayesian methods. Genomic feature best linear unbiased prediction (GFBLUP) models can be fitted. We have extended these models to include multiple features and multiple traits. Different genetic models (e.g. additive, dominance, gene by gene and gene by environment interactions) can be used. Further extensions include a weighted GFBLUP model using differential weighting of the individual genetic marker relationships. Furthermore we have implemented a number of marker set tests. These approaches are computationally very fast allowing rapid analyses of different layers of genomic feature classes to discover genomic features potentially enriched for causal variants. Such information can be used to built more accurate prediction models.
