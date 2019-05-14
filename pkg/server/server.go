package server

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

type Config struct {
	Bind string `env:"BIND" envDefault:":3001"`
}
type Server struct {
	config *Config
}

func Run(ctx context.Context, conf *Config) error {
	server := &Server{
		config: conf,
	}

	app := gin.New()

	writer := logrus.New().Writer()
	defer writer.Close()

	app.Use(gin.LoggerWithWriter(writer))
	app.Use(gin.Recovery())

	if html, err := NewRenderer(); err != nil {
		return err
	} else {
		app.SetHTMLTemplate(html)
	}
	// TODO manifest
	// TODO service worker

	//app.Use(server.basicAuth)
	app.GET("/", server.index)
	//app.PUT("/token", server.authz("root"), server.newToken)
	// TODO
	//app.PUT("/event", server.fire) // fire event via http put request
	//app.GET("/peer", server.authz("peer"))

	errc := make(chan error)
	go func() {
		errc <- app.Run(conf.Bind)
	}()

	select {
	case err := <-errc:
		return err
	case <-ctx.Done():
		return nil
	}
	return nil
}
func (server *Server) index(c *gin.Context) {
	c.HTML(http.StatusOK, "index.html", gin.H{})
}
