####################################################################################################################
#    Module 4: GREML analysis
####################################################################################################################
#'
#' Genomic REML analysis
#'
#' @description
#' The greml function is used for estimation of genomic parameters (co-variance, heritability and correlation) 
#' for linear mixed models using restricted maximum likelihood estimation (REML) and genomic prediction using 
#' best linear unbiased prediction (BLUP).
#' 
#' The linear mixed model can account for multiple genetic factors (fixed and random genetic marker effects), 
#' adjust for complex family relationships or population stratification, and adjust for other non-genetic factors 
#' including lifestyle characteristics. Different genetic architectures (infinitesimal, few large and many 
#' small effects) is accounted for by modeling genetic markers in different sets as fixed or random effects 
#' and by specifying individual genetic marker weights. Different genetic models (e.g. additive and non-additive) 
#' can be specified by providing additive and non-additive genomic relationship matrices (GRMs) (constructed using grm). 
#' The GRMs can be accessed from the R environment or from binary files stored on disk facilitating analyses of 
#' large-scale genetic data.
#' 
#' The output contains estimates of variance components, fixed and random effects, first and second derivatives of 
#' log-likelihood, and the asymptotic standard deviation of parameter estimates.
#' 
#' Assessment of predictive accuracy (including correlation and R2, and AUC for binary phenotypes) can be obtained 
#' by providing greml with a dataframe or list containing sample IDs used in the validation, see examples for details.
#' 
#' Genomic parameters can also be estimated with DMU (http://www.dmu.agrsci.dk/DMU/) if interface =”DMU”. 
#' This option requires DMU to be installed locally, and the path to the DMU binary files has to be specified 
#' (see examples below for details).

#' @param y vector or matrix of phenotypes
#' @param X design matrix for factors modeled as fixed effects
#' @param GRM list of one or more genomic relationship matrices 
#' @param GRMlist list providing information about GRM matrix stored in binary files on disk
#' @param theta vector of initial values of co-variance for REML estimation 
#' @param ids vector of individuals used in the analysis 
#' @param validate dataframe or list of individuals used in cross-validation (one column/row for each validation set)
#' @param maxit maximum number of iterations used in REML analysis
#' @param tol tolerance, i.e. convergence criteria used in REML
#' @param ncores number of cores used for the analysis
#' @param fm formula with model statement for the linear mixed model 
#' @param data data frame containing the phenotypic observations and fixed factors specified in the model statements
#' @param interface used for specifying whether to use R or Fortran implementations of REML
#' @param bin directory for fortran binaries (e.g. DMU binaries dmu1 and dmuai)

#' 
#' @return Returns a list structure including
#' \item{llik}{log-likelihood at convergence}
#' \item{theta}{covariance estimates from REML}
#' \item{asd}{asymptotic standard deviation}
#' \item{b}{vector of fixed effect estimates}
#' \item{varb}{vector of variances of fixed effect estimates}
#' \item{g}{vector or matrix of random effect estimates}
#' \item{e}{vector or matrix of residual effects}
#' \item{accuracy}{matrix of prediction accuracies (only returned if validate is provided)}


#' @author Peter Soerensen


#' @references Lee, S. H., & van Der Werf, J. H. (2006). An efficient variance component approach implementing an average information REML suitable for combined LD and linkage mapping with a general complex pedigree. Genetics Selection Evolution, 38(1), 25.

#' @examples
#'
#' # Simulate data
#' W <- matrix(rnorm(20000000), ncol = 10000)
#' 	colnames(W) <- as.character(1:ncol(W))
#' 	rownames(W) <- as.character(1:nrow(W))
#' y <- rowSums(W[, 1:10]) + rowSums(W[, 1001:1010]) + rnorm(nrow(W))
#'
#' # Create model
#' data <- data.frame(y = y, mu = 1)
#' fm <- y ~ 0 + mu
#' X <- model.matrix(fm, data = data)
#'
#' # Compute GRM
#' GRM <- grm(W = W)
#'
#' # REML analyses
#' fitG <- greml(y = y, X = X, GRM = list(GRM))
#'
#' # REML analyses and cross validation
#' 
#' # Create marker sets
#' setsGB <- list(A = colnames(W)) # gblup model
#' setsGF <- list(C1 = colnames(W)[1:1000], C2 = colnames(W)[1001:2000], C3 = colnames(W)[2000:10000]) # gfblup model
#' setsGT <- list(C1 = colnames(W)[1:10], C2 = colnames(W)[1001:1010], C3 = colnames(W)[1:10000]) # true model
#' 
#' GB <- lapply(setsGB, function(x) {grm(W = W[, x])})
#' GF <- lapply(setsGF, function(x) {grm(W = W[, x])})
#' GT <- lapply(setsGT, function(x) {grm(W = W[, x])})
#' 
#' n <- length(y)
#' fold <- 10
#' nvalid <- 5
#' 
#' validate <- replicate(nvalid, sample(1:n, as.integer(n / fold)))
#' cvGB <- greml(y = y, X = X, GRM = GB, validate = validate)
#' cvGF <- greml(y = y, X = X, GRM = GF, validate = validate)
#' cvGT <- greml(y = y, X = X, GRM = GT, validate = validate)
#'
#' cvGB$accuracy
#' cvGF$accuracy
#' cvGT$accuracy
#' 
#' 
#' # bin <- "C:/Program Files (x86)/QGG-AU/DMUv6/R5.2-EM64T/bin"
#' # data <- data.frame(f = factor(sample(1:2, nrow(W), replace = TRUE)), g = factor(1:nrow(W)), y = y)
#' # fm <- y ~ f + (1 | g~G) 
#' # fit <- greml(fm = list(fm), GRM = list(G=G), data = data, interface="DMU")
#' # str(fit)

#' 
#' @export
#'

  greml <- function(y = NULL, X = NULL, GRMlist=NULL, GRM=NULL, theta=NULL, ids=NULL, validate=NULL, maxit=100, tol=0.00001,bin=NULL,ncores=1,wkdir=getwd(), verbose=FALSE, makeplots=FALSE,interface="R", fm=NULL,data=NULL) {

      if(interface=="DMU") {
        fit <- remlDMU(fm = fm, GRM = GRM, data = data)
        remlDMU(fm = fm, GRM = GRM, restrict = restrict, data = data, validate = validate, bin = bin) 
          
      return(fit)
     }
     
  if(!interface=="DMU") {
          
 #if(interface=="R") {
  if(!is.null(GRM)) {
    if (is.null(validate)) fit <- remlR(y=y, X=X, GRMlist=GRMlist, G=GRM, theta=theta, ids=ids, maxit=maxit, tol=tol, bin=bin, ncores=ncores, verbose=verbose, wkdir=wkdir)
    if (!is.null(validate)) fit <- cvreml(y=y, X=X, GRMlist=GRMlist, G=GRM, theta=theta, ids=ids, validate=validate, maxit=maxit, tol=tol, bin=bin, ncores=ncores, verbose=verbose, wkdir=wkdir, makeplots=makeplots)
  }
  if(!is.null(bin)) { 
    fit <- remlF(y=y, X=X, GRMlist=GRMlist, G=GRM, ids=ids, theta=theta, maxit=maxit, tol=tol, bin=bin, ncores=ncores, verbose=verbose, wkdir=wkdir)
  }
  #if(interface=="fortran") {
  if(!is.null(GRMlist)) {
    fit <- freml(y=y, X=X, GRMlist=GRMlist, G=GRM, theta=theta, ids=ids, maxit=maxit, tol=tol, ncores=ncores, verbose=verbose) 
  }        
  return(fit)
  }
}  


####################################################################################################################
# REML interface functions for fortran executable

remlF <- function(y = NULL, X = NULL, GRMlist = NULL, G = NULL, theta = NULL, ids = NULL, maxit = 100, tol = 0.00001, bin = NULL, ncores = 1, wkdir = getwd(), verbose = FALSE ) {
#greml <- function(y = NULL, X = NULL, GRMlist = NULL, G = NULL, ids = NULL, theta = NULL, maxit = 100, tol = 0.00001, bin = NULL, ncores = 1, wkdir = getwd()) {
    
	write.reml(y = as.numeric(y), X = X, G = G)
	n <- length(y)
	nf <- ncol(X)
	if (!is.null(G)) fnamesG <- paste("G", 1:length(G), sep = "")
	if (!is.null(GRMlist$fnG)) fnamesG <- GRMlist$fnG
	nr <- length(fnamesG) + 1
 	if (is.null(ids)) {indxG <- c(n, 1:n)} 
	if (!is.null(ids)) {indxG <- c(GRMlist$n, match(ids, GRMlist$idsG))} 
	write.table(indxG, file = "indxg.txt", quote = FALSE, sep = " ", col.names = FALSE, row.names = FALSE)

	write.table(paste(n, nf, nr, maxit, ncores), file = "param.txt", quote = FALSE, sep = " ", col.names = FALSE, row.names = FALSE)
	if (is.null(theta)) theta <- rep(sd(y) / nr, nr)
	#if (is.null(theta)) theta <- rep(var(y) / nr, nr)
	write.table(t(theta), file = "param.txt", quote = FALSE, sep = " ", append = TRUE, col.names = FALSE, row.names = FALSE)
	write.table(tol, file = "param.txt", quote = FALSE, sep = " ", append = TRUE, col.names = FALSE, row.names = FALSE)
	write.table(fnamesG, file = "param.txt", quote = TRUE, sep = " ", append = TRUE, col.names = FALSE, row.names = FALSE)

	execute.reml(bin = bin,  ncores = ncores)
	fit <- read.reml(wkdir = wkdir)
	fit$y <- y
	fit$X <- X
	fit$ids <- names(y)
	fit$yVy <- sum(y * fit$Vy)
	fit$fnamesG <- fnamesG
	fit$wd <- getwd()
	fit$GRMlist <- GRMlist

	clean.reml(wkdir = wkdir)
      
	return(fit)
      
}


write.reml <- function(y = NULL, X = NULL, G = NULL) {
    
	fileout <- file("y", "wb")
	writeBin(y, fileout)
	close(fileout)
      
	filename <- "X"
	fileout <- file(filename, "wb")
	for (i in 1:nrow(X)) {writeBin(X[i, ], fileout)}
	close(fileout)
  
	if (!is.null(G)) {
	 for (i in 1:length(G)) {
	   fileout <- file(paste("G", i, sep = ""), "wb")
	   nr <- nrow(G[[i]])
	   for (j in 1:nr) {
		writeBin(as.double(G[[i]][1:nr, j]), fileout,size=8,endian = "little")
	   }
	   close(fileout)
	  }
	}
          
}

execute.reml  <- function (bin = NULL, ncores = ncores) {

	HW <- Sys.info()["machine"]
	OS <- .Platform$OS.type
	if (OS == "windows") {
		"my.system" <- function(cmd) {return(system(paste(Sys.getenv("COMSPEC"), "/c", cmd)))}
        
		#my.system(paste("set MKL_NUM_THREADS = ", ncores))
		test <- my.system(paste(shQuote(bin), " < param.txt > reml.lst", sep = ""))
	}
	if (!OS == "windows") {
		system(paste("cp ", bin, " reml.exe", sep = ""))
		#system(paste("export MKL_NUM_THREADS=", ncores))
		system("time ./reml.exe < param.txt > reml.lst")
	}
      
} 
   
read.reml <- function (wkdir = NULL) {
    
	llik <- read.table(file = "llik.qgg", header = FALSE, colClasses = "numeric")
	names(llik) <- "logLikelihood" 
	theta <- read.table(file = "theta.qgg", header = FALSE, colClasses = "numeric")
	colnames(theta) <- "Estimate"
	rownames(theta) <- 1:nrow(theta)
	asd <- read.table(file = "thetaASD.qgg", header = FALSE, colClasses = "numeric") 
	colnames(asd) <- rownames(asd) <- 1:ncol(asd)
	b <- read.table(file = "beta.qgg", header = FALSE, colClasses = "numeric")    
	colnames(b) <- "Estimate"
	rownames(b) <- 1:nrow(b)
	varb <- read.table(file = "betaASD.qgg", header = FALSE, colClasses = "numeric")    
	colnames(varb) <- rownames(varb) <- 1:nrow(b)
	u <- read.table(file = "uhat.qgg", header = FALSE, colClasses = "numeric")
	colnames(u) <- 1:(nrow(theta) - 1)
	e <- read.table(file = "residuals.qgg", header = FALSE, colClasses = "numeric")    
	colnames(e) <- "residuals"
	rownames(e) <- rownames(u) <- 1:nrow(u)
	Vy <- read.table(file = "Vy.qgg", header = FALSE, colClasses = "numeric")    
	rownames(Vy) <- 1:nrow(u)
	Py <- read.table(file = "Py.qgg", header = FALSE, colClasses = "numeric")    
	rownames(Py) <- 1:nrow(u)
	trPG <- as.vector(unlist(read.table(file = "trPG.qgg", header = FALSE, colClasses = "numeric")[, 1]))    
	names(trPG) <- 1:nrow(theta)
	trVG <- as.vector(unlist(read.table(file = "trVG.qgg", header = FALSE, colClasses = "numeric")[, 1]))    
	names(trVG) <- 1:nrow(theta)
	fit <- list(llik = llik, theta = theta, asd = asd, b = b, varb = varb, g = u, e = e, Vy = Vy, Py = Py, trPG = trPG, trVG = trVG)
	fit <- lapply(fit, as.matrix)
      
	return(fit)
      
}

clean.reml <- function(wkdir = NULL) {
    
	fnames <- c("llik.qgg", "theta.qgg", "thetaASD.qgg", "beta.qgg", "betaASD.qgg", 
				"uhat.qgg", "residuals.qgg", "Vy.qgg", "Py.qgg", "trPG.qgg", "trVG.qgg") 
	file.remove(fnames)
      
}



####################################################################################################################
# REML R functions 

remlR <- function(y=NULL, X=NULL, GRMlist=NULL, G=NULL, theta=NULL, ids=NULL, maxit=100, tol=0.00001, bin=NULL,ncores=1,wkdir=getwd(), verbose=FALSE )
  
{
  
  np <- length(G) + 1
  if (is.null(theta)) theta <- rep(sd(y)/np**2,np)
  n <- length(y)
  ai <- matrix(0, ncol=np, nrow=np)
  s <- matrix(0, ncol=1, nrow=np)
  tol <- 0.00001
  delta <- 100
  it <- 0
  G[[np]] <- diag(1,length(y))
  
  while ( max(delta)>tol ) {
    V <- matrix(0,n,n)
    u <- Pu <- matrix(0,nrow=n,ncol=np)
    it <- it + 1
    for ( i in 1:np) { V <- V + G[[i]]*theta[i] }
    Vi <- chol2inv(chol(V))
    remove(V)
    XViXi <- chol2inv(chol(crossprod(X,crossprod(Vi,X) ) ) )
    ViX <- crossprod(Vi,X) 
    ViXXViXi <- tcrossprod(ViX,XViXi)
    remove(XViXi)
    P <- Vi - tcrossprod(ViXXViXi,ViX)
    remove(Vi)
    Py <- crossprod(P,y)
    for ( i in 1:np) {
      u[,i] <- crossprod(G[[i]],Py)
      Pu[,i] <- crossprod(P,u[,i])
    }
    for ( i in 1:np) {
      for ( j in i:np) {
        ai[i,j] <- 0.5*sum(u[,i]*Pu[,j])
        ai[j,i] <- ai[i,j]
      }
      if (i<np) s[i,1] <- -0.5*(sum(G[[i]]*P)-sum(u[,i]*Py))
      if (i==np) s[i,1] <- -0.5*(sum(diag(P))-sum(Py*Py))
    }
    theta.cov <- solve(ai)
    theta0 <- theta + solve(ai)%*%s
    theta0[theta0<0] <- 0.000000001
    delta <- abs(theta - theta0)
    theta <- theta0
    output <- c(1:10,seq(11,maxit,5))     
    if (verbose & it%in%output) print(paste(c("Iteration:",it,"Theta:",round(theta,2)), sep=""))
    if (it==maxit) break
  }
  if (verbose) print(paste(c("Converged at Iteration:",it,"Theta:",round(theta,2)), sep=""))
  V <- matrix(0,n,n)
  for ( i in 1:np) { V <- V + G[[i]]*theta[i] }
  chlV <- chol(V)
  remove(V)
  ldV <- log(sum(diag(chlV)))
  Vi <- chol2inv(chlV)
  remove(chlV)
  chlXVX <- chol(crossprod(X,crossprod(Vi,X) ))
  ldXVX <- log(sum(diag(chlXVX)))
  XViXi <- chol2inv(chlXVX)
  ViX <- crossprod(Vi,X)
  ViXXViXi <- tcrossprod(ViX,XViXi)
  b <- crossprod(ViXXViXi,y)
  vb <- XViXi
  P <- Vi - tcrossprod(ViXXViXi,ViX)
  trPG <- trVG <- rep(0,length(theta))
  for (i in 1:np) {
    trVG[i] <- sum(Vi*G[[i]])
    trPG[i] <- sum(P*G[[i]])
  } 
  Vy <- crossprod(Vi,y)
  remove(Vi)
  Py <- crossprod(P,y)
  yPy <- sum(y*Py)
  yVy <- sum(y*Vy)
  llik <- -0.5*(ldV+ldXVX+yPy)
  
  u <- NULL
  for (i in 1:(length(theta)-1)) {
    u <- cbind(u, crossprod(G[[i]]*theta[i],Py) )       
  }
  fitted <- X%*%b
  predicted <- rowSums(u)+fitted
  e <- y-predicted
  theta <- as.vector(theta)
  if(is.null(names(G))) names(theta) <- c(paste("G",1:(np-1),sep=""),"E")
  if(!is.null(names(G))) names(theta) <- c(names(G)[-np],"E")
  if(is.null(names(G))) colnames(u) <- c(paste("G",1:(np-1),sep=""))
  if(!is.null(names(G))) colnames(u) <- names(G)[-np]
  
  return(list( y=y, X=X, b=b, vb=vb, g=u, e=e, fitted=fitted, predicted=predicted, Py=Py, Vy=Vy, theta=theta, asd=theta.cov, llik=llik, niter=it,trPG=trPG, trVG=trVG,ids=names(y),yVy=yVy   ))
}


cvreml <- function(y=NULL, X=NULL, GRMlist=NULL, G=NULL, theta=NULL, ids=NULL, validate=NULL, maxit=100, tol=0.00001,bin=NULL,ncores=1,wkdir=getwd(), verbose=FALSE, makeplots=FALSE)
{
  n <- length(y)     
  theta <- yobs <- ypred <- yo <- yp <- NULL
  res <- NULL
  if(is.matrix(validate)) validate <- as.data.frame(validate)
  nv <- length(validate)
  typeoftrait <- "quantitative"
  if(nlevels(factor(y))==2) typeoftrait <- "binary" 
  for (i in 1:nv) {
    v <- validate[[i]]  
    t <- (1:n)[-v]
    fit <- remlR( y=y[t], X=X[t,], G=lapply(G,function(x){x[t,t]}), verbose=verbose)
    theta <- rbind(theta, as.vector(fit$theta))
    np <- length(fit$theta)
    ypred <- X[v, ] %*% fit$b
    for (j in 1:(np-1)) {
      ypred <- ypred + G[[j]][v,t]%*%fit$Py*fit$theta[j]
    }
    yobs <- y[v]
    if(!is.atomic(validate)) res <- rbind(res,acc(yobs=yobs,ypred=ypred,typeoftrait=typeoftrait))
    yo <- c(yo, yobs)
    yp <- c(yp, ypred)
  }

  if(is.atomic(validate)) res <- matrix(acc(yobs=yo,ypred=yp,typeoftrait=typeoftrait),nrow=1)
  #if(is.atomic(validate)) res <- matrix(qcpred(yobs=yo,ypred=yp,typeoftrait=typeoftrait),nrow=1)
  res <- as.data.frame(res)
  names(res) <- c("Corr","R2","Nagel R2", "AUC", "intercept", "slope", "MSPE")
  if(is.null(names(G))) names(G) <- paste("G",1:(np-1),sep="")
  colnames(theta) <- c(names(G),"E")
  theta <- as.data.frame(round(theta,3))
  if (makeplots) {
   layout(matrix(1:4, ncol = 2))
   boxplot(res$Corr, main = "Predictive Ability", ylab = "Correlation")
   boxplot(res$MSPE, main = "Prediction Error", ylab = "MSPE")
   boxplot(theta, main = "Estimates", ylab = "Variance")
   plot(y=yo, x=yp, xlab = "Predicted", ylab = "Observed")
   coef <- lm(yo ~ yp)$coef
   abline(a = coef[1], b = coef[2], lwd = 2, col = 2, lty = 2)
  }
  return(list(accuracy=res,theta=theta,yobs=yo,ypred=yp))
}


####################################################################################################################
# REML interface functions for fortran linked library

#' @export
#'

freml <- function(y = NULL, X = NULL, GRMlist = NULL, G = NULL, theta = NULL, ids = NULL, maxit = 100, tol = 0.00001, ncores = 1, verbose = FALSE ) 

{

   if(!is.null(G)) writeG(G = G)

   ids <- names(y)

   n <- length(y)
   nf <- ncol(X)
   if (!is.null(G)) rfnames <- paste("G", 1:length(G), sep = "")
   if (!is.null(G)) rfnames <- paste(getwd(),rfnames,sep="/")	 
   if (!is.null(GRMlist)) rfnames <- GRMlist$fnG
   nr <- length(rfnames) + 1
   if (!is.null(G)) ngr <- nrow(G[[1]])
   if (!is.null(G)) indx <- match(ids, rownames(G[[1]]))
   if (!is.null(GRMlist)) ngr <- GRMlist$n
   if (!is.null(GRMlist)) indx <- match(ids, GRMlist$idsG)
   
   fnr <- paste(paste(sample(letters,10,replace=TRUE),collapse=""),".qgg",sep="")

   write.table( as.character(rfnames), file=fnr, quote = TRUE, sep = " ", col.names=FALSE, row.names=FALSE)
   
   
   fit <- .Fortran("reml", 
          n = as.integer(n),
          nf = as.integer(nf),
          nr = as.integer(nr),
          tol = as.double(tol),
          maxit = as.integer(maxit),
          ncores = as.integer(ncores),
          fnr = as.character(fnr),
          #rfnames = as.character(rfnames),
          ngr = as.integer(ngr),
          indx = as.integer(indx),
          y = as.double(y),
          X = matrix(as.double(X),nrow=nrow(X)),
          theta = as.double(theta),
          ai = matrix(as.double(0),nrow=nr,ncol=nr),
          b = as.double(rep(0,nf)),
          varb = matrix(as.double(0),nrow=nf,ncol=nf),
          u = matrix(as.double(0),nrow=n,ncol=nr),
          Vy = as.double(rep(0,n)),
          Py = as.double(rep(0,n)),
          llik = as.double(0),
          trPG = as.double(rep(0,nr)),
          trVG = as.double(rep(0,nr)),
          PACKAGE = 'qgg'
   )
   
   fit$ids <- names(y)
   fit$yVy <- sum(y * fit$Vy)
   fit$wd <- getwd()
   fit$GRMlist <- GRMlist
   rownames(fit$u) <- names(y)
   colnames(fit$u) <- c(paste("G",1:(ncol(fit$u)-1),sep=""),"E1")
   fit$g <- fit$u[,1:(nr-1)]
   fit$e <- fit$u[,nr]
   fit$u <- NULL 
   np <- length(fit$theta)
   names(fit$theta) <- c(paste("G",1:(np-1),sep=""),"E")
   
   return(fit)
}

#' @export
#'


writeG <- function(G = NULL) {
   if (!is.null(G)) {
     for (i in 1:length(G)) {
      fileout <- file(paste("G", i, sep = ""), "wb")
      nr <- nrow(G[[i]])
      for (j in 1:nr) {
        writeBin(as.double(G[[i]][1:nr, j]), fileout,size=8,endian = "little")
      }
      close(fileout)
     }
   }
}


#' @export
#'

gblup <- function(GRMlist=NULL,G=NULL,fit=NULL,g=NULL, ids=NULL, idsCLS=NULL, idsRWS=NULL) {
     GRMlist <- fit$GRMlist
     fnG <- GRMlist$fnG
     Py <- fit$Py
     names(Py) <- fit$ids
     g <- NULL
     nr <- length(fnG)
     if(is.null(idsCLS)) idsCLS <- fit$ids
     if(is.null(idsRWS)) idsRWS <- fit$ids
     if(!is.null(ids)) idsRWS <- ids
     if (sum(!idsRWS%in%GRMlist$idsG)>0) stop("Error some ids not found in idsG")
     for (i in 1:nr) {
          GRMlist$fnG <- fnG[i]  
          G <- getGRM(GRMlist=GRMlist, idsCLS=idsCLS,idsRWS=idsRWS) 
          g <- cbind(g, G%*%Py[idsCLS]*fit$theta[i])
     }
     colnames(g) <- paste("G",1:nr,sep="")
     return(g)
} 

