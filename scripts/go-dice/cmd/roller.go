package cmd

import "math/rand"

type DN struct {
	NumSides int
}

type SingleResult struct {
	DN            DN
	IntegerResult int
}

type Result = []SingleResult

type Roller struct {
	History []Result
}

func NewRoller() *Roller {
	return &Roller{History: make([]Result, 0)}
}

func (r *Roller) roll(dice []DN) Result {
	results := make([]SingleResult, 0)
	for _, dn := range dice {
		intResult := rand.Intn(dn.NumSides) + 1
		results = append(results, SingleResult{DN: dn, IntegerResult: intResult})
	}
	return results
}
