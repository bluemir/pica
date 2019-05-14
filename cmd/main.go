package main

import (
	"context"
	"fmt"

	"github.com/caarlos0/env"

	"github.com/bluemir/pica/pkg/server"
)

func main() {
	conf := &server.Config{}
	if err := env.Parse(conf); err != nil {
		fmt.Printf("%+v\n", err)
	}

	if err := server.Run(context.Background(), conf); err != nil {
		fmt.Printf("%+v\n", err)
	}
}
