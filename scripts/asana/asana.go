package asana

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
)

// URLs

var baseURL = "https://app.asana.com/api/1.0"
var workspacesURL = fmt.Sprintf("%v/workspaces", baseURL)

func getTaskSearchURL(workspaceID string) string {
	return fmt.Sprintf("%v/workspaces/%v/tasks/search", baseURL, workspaceID)
}

// Types

type AsanaClient struct {
	APIKey string
}

type AsanaTask struct {
	Text    string    `json:"name"`
	DueDate string    `json:"due_on"`
	DueTime time.Time `json:"due_at"`
	ID      string    `json:"gid"`
}

type AsanaWorkspace struct {
	Name string `json:"name"`
	ID   string `json:"gid"`
}

type asanaResponse[T any] struct {
	Data []T `json:"data"`
}

func (a *AsanaClient) GetWorkspaces() ([]AsanaWorkspace, error) {
	if err := a.checkAPIKey(); err != nil {
		return nil, err
	}
	req, err := a.newAsanaRequest(http.MethodGet, workspacesURL)
	if err != nil {
		return nil, err
	}

	req.Header.Add("opt_fields", "")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	response := asanaResponse[AsanaWorkspace]{}
	err = json.Unmarshal(body, &response)
	if err != nil {
		return nil, err
	}
	return response.Data, nil
}

func (a *AsanaClient) GetTasks(workspaceID string) ([]AsanaTask, error) {
	if err := a.checkAPIKey(); err != nil {
		return nil, err
	}

	req, err := a.newAsanaRequest(http.MethodGet, getTaskSearchURL(workspaceID))
	if err != nil {
		return nil, err
	}

	now := time.Now()
	currentWeekday := now.Weekday()
	var dueOnBefore time.Time
	if currentWeekday == time.Friday {
		dueOnBefore = now.Add(time.Hour * 24 * 4)
	} else {
		dueOnBefore = now.Add(time.Hour * 24 * 2)
	}

	q := req.URL.Query()
	q.Add("assignee.any", "me")
	q.Add("due_on.before", dueOnBefore.Format("2006-01-02"))
	q.Add("completed", "false")
	q.Add("opt_fields", "due_on,due_at,name")
	q.Add("sort_by", "due_date")
	req.URL.RawQuery = q.Encode()

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	response := asanaResponse[AsanaTask]{}
	err = json.Unmarshal(body, &response)
	if err != nil {
		return nil, err
	}

	return response.Data, nil
}

// Unexported helpers

func (a *AsanaClient) checkAPIKey() error {
	if a.APIKey == "" {
		return errors.New("Asana API key is missing.")
	}
	return nil
}

func (a *AsanaClient) newAsanaRequest(method, url string) (req *http.Request, err error) {
	if err = a.checkAPIKey(); err != nil {
		return nil, err
	}
	req, err = http.NewRequest(method, url, nil)
	if err != nil {
		return
	}
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %v", a.APIKey))
	return
}
