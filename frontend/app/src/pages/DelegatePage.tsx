import { withTranslation, WithTranslation } from 'react-i18next';
import * as Yup from 'yup';
import styled from '@emotion/styled';
import { AxiosError } from 'axios';
import { useQuery } from 'react-query';
import { Field, Form, Formik } from 'formik';
import { Button, Grid, Paper } from '@material-ui/core';
import { useToasts } from 'react-toast-notifications';
import { useHistory } from 'react-router-dom';
import { getDelegates } from '../api/tzkt';
import { create, cTezError, delegate } from '../contracts/ctez';
import Page from '../components/Page';
import { FormikAutocomplete } from '../components/Autocomplete';
import { Baker } from '../interfaces';

interface DelegateForm {
  delegate: string;
}

const PaperStyled = styled(Paper)`
  padding: 2em;
  & .delegate {
    min-width: 40rem;
  }
`;

const DelegateComponent: React.FC<WithTranslation> = ({ t }) => {
  const { data: delegates } = useQuery<Baker[], AxiosError, Baker[]>(['delegates'], () => {
    return getDelegates();
  });
  const { addToast } = useToasts();
  const history = useHistory();
  const initialValues: DelegateForm = {
    delegate: '',
  };

  const validationSchema = Yup.object().shape({
    delegate: Yup.string().required(t('required')),
  });

  const handleFormSubmit = async (data: DelegateForm) => {
    try {
      const result = await delegate(data.delegate);
      if (result) {
        addToast('Transaction Submitted', {
          appearance: 'success',
          autoDismiss: true,
          onDismiss: () => history.push('/'),
        });
      }
    } catch (error) {
      const errorText = cTezError[error.data[1].with.int as number] || 'Transaction Failed';
      addToast(errorText, {
        appearance: 'error',
        autoDismiss: true,
      });
    }
  };

  return (
    <Page title={t('delegate')}>
      <Formik
        initialValues={initialValues}
        validationSchema={validationSchema}
        onSubmit={handleFormSubmit}
      >
        {({ isSubmitting, isValid, dirty }) => (
          <PaperStyled>
            <Form>
              <Grid
                container
                spacing={3}
                direction="column"
                alignContent="center"
                justifyContent="center"
              >
                <Grid item>
                  <Field
                    component={FormikAutocomplete}
                    name="delegate"
                    id="delegate"
                    label={t('delegate')}
                    placeholder={t('delegatePlaceholder')}
                    options={delegates}
                    className="delegate"
                  />
                </Grid>
                <Grid item>
                  <Button
                    variant="contained"
                    type="submit"
                    disabled={isSubmitting || !isValid || !dirty}
                    fullWidth
                  >
                    {t('submit')}
                  </Button>
                </Grid>
              </Grid>
            </Form>
          </PaperStyled>
        )}
      </Formik>
    </Page>
  );
};

export const DelegatePage = withTranslation(['common'])(DelegateComponent);
