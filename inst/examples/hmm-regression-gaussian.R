mySpec <- hmm(
  K = 2, R = 1,
  observation = RegGaussian(
    xBeta = Gaussian(mu = 0, sigma = 10),
    sigma = Student(mu = 0, sigma = 10, nu = 1, bounds = list(0, NULL)),
    M     = 3
  ),
  initial     = Dirichlet(alpha = c(1, 1)),
  transition  = Dirichlet(alpha = c(1, 1)),
  name = "Univariate Gaussian Regression"
)

set.seed(9000)
x <- as.matrix(
  cbind(
    rep(1, 300),
    rnorm(300),
    rnorm(300)
  )
)
y <- as.matrix(
  c(
    x[  1:150, ] %*% c(-1, -0.7,  1.5) + rnorm(150),
    x[151:300, ] %*% c( 2,  3.8, -4.5) + rnorm(150)
  )
)

myModel <- compile(mySpec)
myFit   <- fit(mySpec, y = y, x = x, chains = 1, iter = 500, seed = 9000)

print(myFit)
