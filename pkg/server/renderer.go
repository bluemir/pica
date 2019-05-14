package server

import (
	"html/template"
	"os"
	"path/filepath"
	"strings"

	rice "github.com/GeertJohan/go.rice"
	"github.com/sirupsen/logrus"
)

func NewRenderer() (*template.Template, error) {
	log := logrus.WithField("method", "NewRenderer")
	tmpl := template.New("__root__")

	box := rice.MustFindBox("../../app/html")
	err := box.Walk("/", func(path string, info os.FileInfo, err error) error {
		if info.IsDir() && info.Name()[0] == '.' && path != "/" {
			return filepath.SkipDir
		}
		if info.IsDir() || info.Name()[0] == '.' || !strings.HasSuffix(path, ".html") {
			return nil
		}
		log.Debugf("parse template: path: %s", path)

		tmpl, err = tmpl.Parse(box.MustString(path))
		if err != nil {
			return err
		}
		return nil
	})

	if err != nil {
		return nil, err
	}
	return tmpl, nil
}
