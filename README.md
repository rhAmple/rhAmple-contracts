<h1 align=center><code>
rebase-hedged Ample
</code></h1>

The rebase-hedged Ample (rhAmple) token is a %-ownership of Ample supply
interest-bearing token, i.e. wAmple interest bearing.

However, the rhAmple token denominates user deposits in Ample.
This is possible by using the [ElasticReceiptToken](https://github.com/pmerkleplant/elastic-receipt-token) which ensures the rhAmple
supply always equals the amount of Amples deposited.

Therefore, the conversion rate of rhAmple:Ample is always 1:1 (outside of
in-transaction states).

This conversion rate can only break _during_ a user's withdrawal transaction
in which rebase-hedged receipt tokens may be selled in the open market.

The rhAmple ERC20 tokens implementes ButtonWood's [IButtonWrapper](https://github.com/buttonwood-protocol/button-wrappers/blob/main/contracts/interfaces/IButtonWrapper.sol) interface.


## Setup

To install with [**Foundry**](https://github.com/gakonst/foundry):
```sh
forge install rhAmple/rhAmple-contracts
```

Common tasks are executed through a `Makefile`:
```sh
make help
> build                    Build project
> clean                    Remove build artifacts
> test                     Run whole testsuite
> testButtonWrapper        Run ButtonWrapper tests
> testDeployment           Run deployment tests
> testOnlyOwner            Run onlyOwner tests
> testRestructure          Run Restructure tests
```


## Dependencys

- [merkleplant's ElasticReceiptToken](https://github.com/pmerkleplant/elastic-receipt-token)
- [byterocket's Ownable](https://github.com/byterocket/ownable)
- [Rari Capital's solmate](https://github.com/rari-capital/solmate)

### Test Dependencies

- [brockelmore's forge-std](https://github.com/brockelmore/forge-std)


## Safety

This is experimental software and is provided on an "as is" and
"as available" basis.

We do not give any warranties and will not be liable for any loss incurred
through any use of this codebase.
