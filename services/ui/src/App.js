import React from 'react';
import {
  HashRouter as Router,
  Switch,
  Route,
  useRouteMatch
} from 'react-router-dom';
import Footer from './components/Footer'
import Fortune from './components/Fortune'
import Header from './components/Header'
import Names from './components/Names'

export default function App() {
  return (
    <Router>
      <a className="usa-skipnav" href="#main-content">
        Skip to main content
      </a>
      <Header />

      <main id="main-content">
        <Switch>
          <Route path="/names">
            <NamesRoute />
          </Route>
          <Route path="/">
            <Fortune />
          </Route>
        </Switch>
      </main>

      <Footer />
    </Router>
  )
}

function NamesRoute() {
  const match = useRouteMatch('/names/:kind');

  return (
    <Names kind={match.params.kind} />
  )
}
